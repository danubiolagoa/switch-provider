use crate::config::{ProviderInfo, Settings};
use crate::error::{AppError, AppResult};
use std::path::{Path, PathBuf};
use tokio::fs;

/// Configuration store for managing provider settings files
pub struct ConfigStore {
    config_dir: PathBuf,
}

impl ConfigStore {
    /// Create a new ConfigStore for the default config directory
    pub async fn new() -> AppResult<Self> {
        let config_dir = crate::error::get_config_dir()?;
        Self::new_with_dir(config_dir).await
    }

    /// Create a new ConfigStore with a custom directory
    pub async fn new_with_dir(config_dir: PathBuf) -> AppResult<Self> {
        // Ensure config directory exists
        fs::create_dir_all(&config_dir)
            .await
            .map_err(AppError::ConfigDir)?;
        let store = Self { config_dir };
        store.migrate_legacy_settings_files().await?;
        Ok(store)
    }

    async fn migrate_legacy_settings_files(&self) -> AppResult<()> {
        let mut entries = fs::read_dir(&self.config_dir)
            .await
            .map_err(AppError::ConfigDir)?;

        while let Some(entry) = entries.next_entry().await.map_err(AppError::ConfigDir)? {
            let path = entry.path();
            if path.extension().and_then(|s| s.to_str()) != Some("json") {
                continue;
            }

            let Some(stem) = path.file_stem().and_then(|s| s.to_str()) else {
                continue;
            };

            if stem != "settings" && !stem.starts_with("settings-") {
                continue;
            }

            let mut settings = match self.read_settings(&path).await {
                Ok(settings) => settings,
                Err(_) => continue,
            };

            if settings.normalize_provider_auth() {
                self.write_settings(&path, &settings).await?;
            }
        }

        Ok(())
    }

    /// Get the path to the active settings.json
    pub fn active_settings_path(&self) -> PathBuf {
        self.config_dir.join("settings.json")
    }

    /// Get the path to a provider settings file
    fn provider_path(&self, name: &str) -> PathBuf {
        self.config_dir.join(format!("settings-{}.json", name))
    }

    /// List all available providers (settings-*.json files)
    pub async fn list_providers(&self) -> AppResult<Vec<ProviderInfo>> {
        let mut entries = fs::read_dir(&self.config_dir)
            .await
            .map_err(AppError::ConfigDir)?;
        let mut providers = Vec::new();

        while let Some(entry) = entries.next_entry().await.map_err(AppError::ConfigDir)? {
            let path = entry.path();
            if path.extension().and_then(|s| s.to_str()) == Some("json") {
                if let Some(stem) = path.file_stem().and_then(|s| s.to_str()) {
                    // Skip settings.json and settings-local.json
                    if stem == "settings" || stem == "settings-local" {
                        continue;
                    }
                    if stem.starts_with("settings-") {
                        let name = stem.replace("settings-", "");
                        let is_active = self.is_active(&name).await?;
                        let settings = self.read_settings(&path).await.ok();
                        let model = settings
                            .as_ref()
                            .and_then(|settings| settings.env.model.clone());
                        let base_url = settings
                            .as_ref()
                            .and_then(|settings| settings.env.base_url.clone());
                        providers.push(ProviderInfo {
                            name,
                            path,
                            is_active,
                            model,
                            base_url,
                        });
                    }
                }
            }
        }

        // Sort by name
        providers.sort_by(|a, b| a.name.cmp(&b.name));
        Ok(providers)
    }

    /// Check if a provider is currently active
    async fn is_active(&self, name: &str) -> AppResult<bool> {
        let provider_path = self.provider_path(name);
        let active_path = self.active_settings_path();

        if provider_path.exists() && active_path.exists() {
            let provider_settings = self.read_settings(&provider_path).await?;
            let active_settings = self.read_settings(&active_path).await?;
            return Ok(provider_settings == active_settings);
        }

        Ok(false)
    }

    /// Read the active settings
    pub async fn read_active(&self) -> AppResult<Option<Settings>> {
        let path = self.active_settings_path();
        if !path.exists() {
            return Ok(None);
        }
        let mut settings = self.read_settings(&path).await?;
        if settings.normalize_provider_auth() {
            self.write_settings(&path, &settings).await?;
        }
        Ok(Some(settings))
    }

    /// Read settings from a specific path
    pub async fn read_settings(&self, path: &Path) -> AppResult<Settings> {
        let content = fs::read_to_string(path)
            .await
            .map_err(AppError::ConfigDir)?;
        serde_json::from_str(&content).map_err(|e| {
            AppError::InvalidSettings(path.to_string_lossy().to_string(), e.to_string())
        })
    }

    /// Read the current provider name from active settings
    pub async fn get_current_provider_name(&self) -> AppResult<Option<String>> {
        let active_path = self.active_settings_path();
        if !active_path.exists() {
            return Ok(None);
        }

        let content = fs::read_to_string(&active_path)
            .await
            .map_err(AppError::ConfigDir)?;
        let settings: Settings = serde_json::from_str(&content)
            .map_err(|e| AppError::InvalidSettings("settings.json".to_string(), e.to_string()))?;

        let providers = self.list_providers().await?;
        for provider in providers {
            if provider.is_active {
                return Ok(Some(provider.name));
            }
            if let Ok(provider_settings) = self.read_settings(&provider.path).await {
                if provider_settings == settings {
                    return Ok(Some(provider.name));
                }
            }
        }

        if settings.env.base_url.is_none() {
            return Ok(Some("anthropic (api key)".to_string()));
        }

        let base_url = settings.env.base_url.as_ref().unwrap();
        if base_url.contains("minimax.io") || base_url.contains("minimaxi.com") {
            return Ok(Some("minimax".to_string()));
        }
        if base_url.contains("openrouter.ai") {
            return Ok(Some("openrouter".to_string()));
        }
        if base_url.contains("opencode.ai/zen/go") {
            return Ok(Some("opencode go".to_string()));
        }
        if base_url.contains("opencode.ai/zen") {
            return Ok(Some("opencode zen".to_string()));
        }
        if base_url.contains("z.ai") {
            return Ok(Some("glm".to_string()));
        }
        if base_url.contains("generativelanguage") {
            return Ok(Some("gemini".to_string()));
        }
        if base_url.contains("openai.com") {
            return Ok(Some("openai".to_string()));
        }

        Ok(Some("custom (base_url)".to_string()))
    }

    /// Save a provider settings file (atomic write with temp file)
    pub async fn save_provider(&self, name: &str, settings: &Settings) -> AppResult<()> {
        let path = self.provider_path(name);
        self.write_settings(&path, settings).await
    }

    /// Activate a provider by copying it to settings.json
    pub async fn activate(&self, name: &str) -> AppResult<()> {
        let provider_path = self.provider_path(name);
        let active_path = self.active_settings_path();

        if !provider_path.exists() {
            return Err(AppError::ProviderNotFound(name.to_string()));
        }

        // Read and validate the settings first
        let mut settings = self.read_settings(&provider_path).await?;
        let mut persisted = settings.normalize_activation_model();
        if settings.normalize_provider_auth() {
            persisted = true;
        }
        if persisted {
            self.write_settings(&provider_path, &settings).await?;
        }

        // Write to active settings (atomic)
        self.write_settings(&active_path, &settings).await
    }

    /// Activate native Anthropic (removes base_url, uses api key directly)
    pub async fn activate_native(&self, api_key: &str) -> AppResult<()> {
        let settings = Settings::native_anthropic(api_key.to_string());
        let active_path = self.active_settings_path();
        self.write_settings(&active_path, &settings).await
    }

    /// Update the model for an existing provider
    pub async fn update_model(&self, name: &str, model: &str) -> AppResult<()> {
        let provider_path = self.provider_path(name);
        let active_path = self.active_settings_path();
        let was_active = self.is_active(name).await?;

        // Read existing settings
        let mut settings = self.read_settings(&provider_path).await?;

        settings.set_model(model);

        // Save provider file
        self.write_settings(&provider_path, &settings).await?;

        // If this is the active provider, also update settings.json
        if was_active {
            self.write_settings(&active_path, &settings).await?;
        }

        Ok(())
    }

    /// Update the model for an active provider that supports model catalogs.
    pub async fn update_active_catalog_model(&self, model: &str) -> AppResult<()> {
        let active_path = self.active_settings_path();
        let mut active_settings = self
            .read_active()
            .await?
            .ok_or_else(|| AppError::ProviderNotFound("settings.json".to_string()))?;

        let provider_type = active_settings
            .provider_type()
            .ok_or_else(|| AppError::ProviderNotFound("settings.json".to_string()))?;
        if !provider_type.needs_model_selection() {
            return Err(AppError::ApiError(
                "A troca dinamica de modelo esta disponivel apenas para providers com catalogo de modelos".to_string(),
            ));
        }

        let active_provider = self
            .list_providers()
            .await?
            .into_iter()
            .find(|provider| provider.is_active)
            .map(|provider| provider.name);

        active_settings.set_model(&provider_type.normalize_model_id(model));
        self.write_settings(&active_path, &active_settings).await?;

        if let Some(provider_name) = active_provider {
            let provider_path = self.provider_path(&provider_name);
            self.write_settings(&provider_path, &active_settings)
                .await?;
        }

        Ok(())
    }

    /// Update the model for the active OpenRouter settings and its matching backup.
    pub async fn update_active_openrouter_model(&self, model: &str) -> AppResult<()> {
        self.update_active_catalog_model(model).await
    }

    /// Delete a provider settings file
    pub async fn delete_provider(&self, name: &str) -> AppResult<()> {
        let path = self.provider_path(name);
        if path.exists() {
            fs::remove_file(&path).await.map_err(AppError::ConfigDir)?;
        }
        Ok(())
    }

    /// Rename a provider
    pub async fn rename_provider(&self, old_name: &str, new_name: &str) -> AppResult<()> {
        let old_path = self.provider_path(old_name);
        let new_path = self.provider_path(new_name);

        if !old_path.exists() {
            return Err(AppError::ProviderNotFound(old_name.to_string()));
        }

        if new_path.exists() {
            return Err(AppError::ProviderAlreadyExists(new_name.to_string()));
        }

        // Read, validate, and write to new location
        let settings = self.read_settings(&old_path).await?;
        self.write_settings(&new_path, &settings).await?;

        // Delete old file
        fs::remove_file(&old_path)
            .await
            .map_err(AppError::ConfigDir)?;

        // If was active, update active settings
        if self.is_active(old_name).await? {
            let active_path = self.active_settings_path();
            self.write_settings(&active_path, &settings).await?;
        }

        Ok(())
    }

    /// Write settings with atomic operation (temp file + rename)
    async fn write_settings(&self, path: &Path, settings: &Settings) -> AppResult<()> {
        // Validate JSON before writing
        let json = serde_json::to_string_pretty(settings)?;

        // Write to temp file first
        let temp_path = path.with_extension("tmp");
        fs::write(&temp_path, json)
            .await
            .map_err(AppError::ConfigDir)?;

        // Create backup of existing file
        if path.exists() {
            let backup_path = path.with_extension("bak");
            fs::copy(path, &backup_path)
                .await
                .map_err(AppError::ConfigDir)?;
        }

        // Atomic rename
        if path.exists() {
            fs::remove_file(path).await.map_err(AppError::ConfigDir)?;
        }
        fs::rename(&temp_path, path)
            .await
            .map_err(AppError::ConfigDir)?;

        Ok(())
    }

    /// Check if the config directory exists
    pub fn exists(&self) -> bool {
        self.config_dir.exists()
    }

    /// Get the config directory path
    pub fn config_dir(&self) -> &Path {
        &self.config_dir
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::config::Settings;

    #[test]
    fn test_provider_path() {
        let store = ConfigStore {
            config_dir: PathBuf::from("/home/user/.claude"),
        };
        assert_eq!(
            store.provider_path("minimax"),
            PathBuf::from("/home/user/.claude/settings-minimax.json")
        );
    }

    fn temp_config_dir(name: &str) -> PathBuf {
        let unique = format!("switch-provider-{}-{}", name, std::process::id());
        std::env::temp_dir().join(unique)
    }

    #[tokio::test]
    async fn update_active_openrouter_model_updates_active_and_backup() {
        let dir = temp_config_dir("openrouter-model");
        let _ = fs::remove_dir_all(&dir).await;
        let store = ConfigStore::new_with_dir(dir.clone()).await.unwrap();

        let settings = Settings::with_base_url(
            "https://openrouter.ai/api".to_string(),
            "test-key".to_string(),
            "anthropic/claude-sonnet-4".to_string(),
        );
        store.save_provider("openrouter", &settings).await.unwrap();
        store.activate("openrouter").await.unwrap();

        store
            .update_active_catalog_model("moonshotai/kimi-k2")
            .await
            .unwrap();

        let active = store.read_active().await.unwrap().unwrap();
        let backup = store
            .read_settings(&store.provider_path("openrouter"))
            .await
            .unwrap();

        assert_eq!(active.model(), Some("moonshotai/kimi-k2"));
        assert_eq!(backup.model(), Some("moonshotai/kimi-k2"));

        let _ = fs::remove_dir_all(&dir).await;
    }

    #[tokio::test]
    async fn update_active_openrouter_model_rejects_non_openrouter() {
        let dir = temp_config_dir("minimax-model");
        let _ = fs::remove_dir_all(&dir).await;
        let store = ConfigStore::new_with_dir(dir.clone()).await.unwrap();

        let settings = Settings::with_base_url(
            "https://api.minimax.io/anthropic".to_string(),
            "test-key".to_string(),
            "MiniMax-M2.7".to_string(),
        );
        store.save_provider("minimax", &settings).await.unwrap();
        store.activate("minimax").await.unwrap();

        let result = store
            .update_active_catalog_model("moonshotai/kimi-k2")
            .await;
        assert!(result.is_err());
        assert_eq!(
            store.read_active().await.unwrap().unwrap().model(),
            Some("MiniMax-M2.7")
        );

        let _ = fs::remove_dir_all(&dir).await;
    }

    #[tokio::test]
    async fn activate_minimax_repairs_openrouter_model_in_backup() {
        let dir = temp_config_dir("minimax-repair");
        let _ = fs::remove_dir_all(&dir).await;
        let store = ConfigStore::new_with_dir(dir.clone()).await.unwrap();

        let settings = Settings::with_base_url(
            "https://api.minimax.io/anthropic".to_string(),
            "test-key".to_string(),
            "~moonshotai/kimi-latest".to_string(),
        );
        store.save_provider("Minimax 2.7", &settings).await.unwrap();
        store.activate("Minimax 2.7").await.unwrap();

        let active = store.read_active().await.unwrap().unwrap();
        let backup = store
            .read_settings(&store.provider_path("Minimax 2.7"))
            .await
            .unwrap();

        assert_eq!(active.model(), Some("MiniMax-M2.7"));
        assert_eq!(backup.model(), Some("MiniMax-M2.7"));

        let _ = fs::remove_dir_all(&dir).await;
    }

    #[tokio::test]
    async fn list_providers_marks_active_by_settings_value_not_raw_text() {
        let dir = temp_config_dir("active-value");
        let _ = fs::remove_dir_all(&dir).await;
        let store = ConfigStore::new_with_dir(dir.clone()).await.unwrap();

        let settings = Settings::with_base_url(
            "https://opencode.ai/zen".to_string(),
            "test-key".to_string(),
            "kimi-k2.5".to_string(),
        );
        store.save_provider("zen", &settings).await.unwrap();
        store.activate("zen").await.unwrap();

        let compact = serde_json::to_string(&settings).unwrap();
        fs::write(store.active_settings_path(), compact).await.unwrap();

        let providers = store.list_providers().await.unwrap();
        let provider = providers
            .iter()
            .find(|provider| provider.name == "zen")
            .unwrap();
        assert!(provider.is_active);
        assert_eq!(
            store.get_current_provider_name().await.unwrap(),
            Some("zen".to_string())
        );

        let _ = fs::remove_dir_all(&dir).await;
    }

    #[tokio::test]
    async fn new_with_dir_migrates_legacy_settings_files() {
        let dir = temp_config_dir("legacy-migration");
        let _ = fs::remove_dir_all(&dir).await;
        fs::create_dir_all(&dir).await.unwrap();

        let legacy = r#"{
  "env": {
    "ANTHROPIC_BASE_URL": "https://opencode.ai/zen/go",
    "ANTHROPIC_AUTH_TOKEN": "legacy-token",
    "ANTHROPIC_API_KEY": "",
    "API_TIMEOUT_MS": "3000000",
    "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC": "1",
    "ANTHROPIC_MODEL": "qwen3.7-max"
  },
  "autoUpdatesChannel": "latest"
}"#;

        fs::write(dir.join("settings.json"), legacy).await.unwrap();
        fs::write(dir.join("settings-GO.json"), legacy).await.unwrap();

        let store = ConfigStore::new_with_dir(dir.clone()).await.unwrap();

        let active = store.read_settings(&dir.join("settings.json")).await.unwrap();
        let provider = store
            .read_settings(&dir.join("settings-GO.json"))
            .await
            .unwrap();

        assert_eq!(active.env.api_key.as_deref(), Some("legacy-token"));
        assert_eq!(provider.env.api_key.as_deref(), Some("legacy-token"));
        assert_eq!(active.env.auth_token.as_deref(), None);
        assert_eq!(provider.env.auth_token.as_deref(), None);

        let _ = fs::remove_dir_all(&dir).await;
    }
}
