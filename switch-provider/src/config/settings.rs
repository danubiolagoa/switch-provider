use serde::{Deserialize, Serialize};

/// Settings JSON structure that maps to Claude Code's settings.json
#[derive(Serialize, Deserialize, Debug, Clone, Default, PartialEq, Eq)]
pub struct Settings {
    #[serde(rename = "env")]
    pub env: SettingsEnv,
    #[serde(rename = "autoUpdatesChannel")]
    #[serde(default)]
    pub auto_updates_channel: String,
}

impl Settings {
    /// Create settings for a provider with base URL
    pub fn with_base_url(base_url: String, auth_token: String, model: String) -> Self {
        let mut settings = Settings {
            env: SettingsEnv {
                base_url: Some(base_url),
                auth_token: Some(auth_token),
                api_key: Some(String::new()),
                timeout_ms: Some("3000000".to_string()),
                disable_nonessential: Some("1".to_string()),
                model: Some(model.clone()),
                small_fast_model: Some(model.clone()),
                sonnet_model: Some(model.clone()),
                opus_model: Some(model.clone()),
                haiku_model: Some(model),
            },
            auto_updates_channel: "latest".to_string(),
        };
        settings.normalize_provider_auth();
        settings
    }

    /// Create settings for native Anthropic (API key only)
    pub fn native_anthropic(api_key: String) -> Self {
        Settings {
            env: SettingsEnv {
                api_key: Some(api_key),
                disable_nonessential: Some("1".to_string()),
                ..Default::default()
            },
            auto_updates_channel: "latest".to_string(),
        }
    }

    /// Check if this is a native Anthropic config (no base_url)
    pub fn is_native(&self) -> bool {
        self.env.base_url.is_none() && self.env.api_key.is_some()
    }

    /// Get the active model (ANTHROPIC_MODEL)
    pub fn model(&self) -> Option<&str> {
        self.env.model.as_deref()
    }

    /// Check if this config targets OpenRouter.
    pub fn is_openrouter(&self) -> bool {
        self.env
            .base_url
            .as_deref()
            .map(|url| url.contains("openrouter.ai"))
            .unwrap_or(false)
    }

    /// Update all model slots used by Claude Code.
    pub fn set_model(&mut self, model: &str) {
        let model = model.to_string();
        self.env.model = Some(model.clone());
        self.env.small_fast_model = Some(model.clone());
        self.env.sonnet_model = Some(model.clone());
        self.env.opus_model = Some(model.clone());
        self.env.haiku_model = Some(model);
    }

    /// Detect the provider family from the configured base URL.
    pub fn provider_type(&self) -> Option<ProviderType> {
        let Some(base_url) = self.env.base_url.as_deref() else {
            return Some(ProviderType::Anthropic);
        };

        if base_url.contains("minimax.io") || base_url.contains("minimaxi.com") {
            return Some(ProviderType::MiniMax);
        }
        if base_url.contains("openrouter.ai") {
            return Some(ProviderType::OpenRouter);
        }
        if base_url.contains("opencode.ai/zen/go") {
            return Some(ProviderType::OpenCodeGo);
        }
        if base_url.contains("opencode.ai/zen") {
            return Some(ProviderType::OpenCodeZen);
        }
        if base_url.contains("z.ai") {
            return Some(ProviderType::ZAI);
        }
        if base_url.contains("generativelanguage") {
            return Some(ProviderType::GoogleAI);
        }
        if base_url.contains("openai.com") {
            return Some(ProviderType::OpenAI);
        }

        Some(ProviderType::Custom)
    }

    /// Normalize provider-specific values before activation.
    pub fn normalize_activation_model(&mut self) -> bool {
        let mut changed = false;

        if let (Some(provider_type), Some(current_model)) = (self.provider_type(), self.model()) {
            let normalized_model = provider_type.normalize_model_id(current_model);
            if normalized_model != current_model {
                self.set_model(&normalized_model);
                changed = true;
            }
        }

        if self.provider_type() == Some(ProviderType::MiniMax) {
            let default_model = ProviderType::MiniMax
                .default_model()
                .unwrap_or("MiniMax-M2.7");
            if self.model() != Some(default_model) {
                self.set_model(default_model);
                changed = true;
            }
        }

        changed
    }

    /// Align auth fields with provider expectations.
    /// Returns true if the settings were modified.
    pub fn normalize_provider_auth(&mut self) -> bool {
        match self.provider_type() {
            Some(ProviderType::OpenCodeGo) => {
                let token = self
                    .env
                    .api_key
                    .as_deref()
                    .filter(|key| !key.is_empty())
                    .map(str::to_string)
                    .or_else(|| {
                        self.env
                            .auth_token
                            .as_deref()
                            .filter(|token| !token.is_empty())
                            .map(str::to_string)
                    });

                let mut changed = false;
                if let Some(token) = token {
                    if self.env.api_key.as_deref() != Some(token.as_str()) {
                        self.env.api_key = Some(token.clone());
                        changed = true;
                    }
                }

                if self
                    .env
                    .auth_token
                    .as_deref()
                    .map(|token| !token.is_empty())
                    .unwrap_or(false)
                {
                    self.env.auth_token = None;
                    changed = true;
                }

                changed
            }
            _ => false,
        }
    }
}

#[derive(Serialize, Deserialize, Debug, Clone, Default, PartialEq, Eq)]
pub struct SettingsEnv {
    #[serde(rename = "ANTHROPIC_BASE_URL")]
    #[serde(skip_serializing_if = "Option::is_none")]
    pub base_url: Option<String>,

    #[serde(rename = "ANTHROPIC_AUTH_TOKEN")]
    #[serde(skip_serializing_if = "Option::is_none")]
    pub auth_token: Option<String>,

    #[serde(rename = "ANTHROPIC_API_KEY")]
    #[serde(skip_serializing_if = "Option::is_none")]
    pub api_key: Option<String>,

    #[serde(rename = "API_TIMEOUT_MS")]
    #[serde(skip_serializing_if = "Option::is_none")]
    pub timeout_ms: Option<String>,

    #[serde(rename = "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC")]
    #[serde(skip_serializing_if = "Option::is_none")]
    pub disable_nonessential: Option<String>,

    #[serde(rename = "ANTHROPIC_MODEL")]
    #[serde(skip_serializing_if = "Option::is_none")]
    pub model: Option<String>,

    #[serde(rename = "ANTHROPIC_SMALL_FAST_MODEL")]
    #[serde(skip_serializing_if = "Option::is_none")]
    pub small_fast_model: Option<String>,

    #[serde(rename = "ANTHROPIC_DEFAULT_SONNET_MODEL")]
    #[serde(skip_serializing_if = "Option::is_none")]
    pub sonnet_model: Option<String>,

    #[serde(rename = "ANTHROPIC_DEFAULT_OPUS_MODEL")]
    #[serde(skip_serializing_if = "Option::is_none")]
    pub opus_model: Option<String>,

    #[serde(rename = "ANTHROPIC_DEFAULT_HAIKU_MODEL")]
    #[serde(skip_serializing_if = "Option::is_none")]
    pub haiku_model: Option<String>,
}

/// Provider type enum
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ProviderType {
    MiniMax,
    OpenRouter,
    OpenCodeZen,
    OpenCodeGo,
    Anthropic,
    ZAI,
    GoogleAI,
    OpenAI,
    Custom,
}

impl ProviderType {
    /// Get the default endpoint for this provider type
    pub fn endpoint(&self) -> Option<&'static str> {
        match self {
            ProviderType::MiniMax => Some("https://api.minimax.io/anthropic"),
            ProviderType::OpenRouter => Some("https://openrouter.ai/api"),
            ProviderType::OpenCodeZen => Some("https://opencode.ai/zen"),
            ProviderType::OpenCodeGo => Some("https://opencode.ai/zen/go"),
            ProviderType::Anthropic => None,
            ProviderType::ZAI => Some("https://api.z.ai/api/anthropic"),
            ProviderType::GoogleAI => Some("https://generativelanguage.googleapis.com"),
            ProviderType::OpenAI => Some("https://api.openai.com/v1"),
            ProviderType::Custom => None,
        }
    }

    /// Get the default model for this provider type
    pub fn default_model(&self) -> Option<&'static str> {
        match self {
            ProviderType::MiniMax => Some("MiniMax-M2.7"),
            ProviderType::OpenRouter => None,
            ProviderType::OpenCodeZen => None,
            ProviderType::OpenCodeGo => None,
            ProviderType::Anthropic => Some("claude-sonnet-4-20250514"),
            ProviderType::ZAI => Some("GLM-4.7"),
            ProviderType::GoogleAI => Some("gemini-2.0-flash"),
            ProviderType::OpenAI => Some("gpt-4o-mini"),
            ProviderType::Custom => None,
        }
    }

    /// Whether this provider needs model selection from API
    pub fn needs_model_selection(&self) -> bool {
        matches!(
            self,
            ProviderType::OpenRouter | ProviderType::OpenCodeZen | ProviderType::OpenCodeGo
        )
    }

    /// Get the model listing endpoint for providers that expose model catalogs.
    pub fn model_list_url(&self) -> Option<&'static str> {
        match self {
            ProviderType::OpenRouter => Some("https://openrouter.ai/api/v1/models"),
            ProviderType::OpenCodeZen => Some("https://opencode.ai/zen/v1/models"),
            ProviderType::OpenCodeGo => Some("https://opencode.ai/zen/go/v1/models"),
            _ => None,
        }
    }

    /// Human readable provider name.
    pub fn display_name(&self) -> &'static str {
        match self {
            ProviderType::MiniMax => "MiniMax",
            ProviderType::OpenRouter => "OpenRouter",
            ProviderType::OpenCodeZen => "OpenCode Zen",
            ProviderType::OpenCodeGo => "OpenCode Go",
            ProviderType::Anthropic => "Anthropic",
            ProviderType::ZAI => "Z.AI",
            ProviderType::GoogleAI => "Google AI",
            ProviderType::OpenAI => "OpenAI",
            ProviderType::Custom => "Custom",
        }
    }

    /// Normalize model ids to the format expected by Claude Code/provider gateways.
    pub fn normalize_model_id(&self, model: &str) -> String {
        let model = model.trim();
        match self {
            ProviderType::OpenCodeZen => model
                .strip_prefix("opencode/")
                .unwrap_or(model)
                .to_string(),
            ProviderType::OpenCodeGo => model
                .strip_prefix("opencode-go/")
                .unwrap_or(model)
                .to_string(),
            _ => model.to_string(),
        }
    }

}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_settings_with_base_url() {
        let settings = Settings::with_base_url(
            "https://api.minimax.io/anthropic".to_string(),
            "my-api-key".to_string(),
            "MiniMax-M2.7".to_string(),
        );
        assert_eq!(
            settings.env.base_url,
            Some("https://api.minimax.io/anthropic".to_string())
        );
        assert_eq!(settings.env.model, Some("MiniMax-M2.7".to_string()));
        assert!(!settings.is_native());
    }

    #[test]
    fn test_with_base_url_populates_go_api_key_only() {
        let settings = Settings::with_base_url(
            "https://opencode.ai/zen/go".to_string(),
            "my-secret-key".to_string(),
            "qwen3.7-max".to_string(),
        );
        assert_eq!(settings.env.auth_token.as_deref(), None);
        assert_eq!(settings.env.api_key.as_deref(), Some("my-secret-key"));
    }

    #[test]
    fn test_normalize_provider_auth_for_opencode_go() {
        let mut settings = Settings {
            env: SettingsEnv {
                base_url: Some("https://opencode.ai/zen/go".to_string()),
                auth_token: Some("legacy-token".to_string()),
                api_key: Some(String::new()),
                ..Default::default()
            },
            auto_updates_channel: "latest".to_string(),
        };

        assert!(settings.normalize_provider_auth());
        assert_eq!(settings.env.api_key.as_deref(), Some("legacy-token"));
        assert_eq!(settings.env.auth_token.as_deref(), None);

        assert!(!settings.normalize_provider_auth());
    }

    #[test]
    fn test_normalize_provider_auth_keeps_existing_go_api_key() {
        let mut settings = Settings {
            env: SettingsEnv {
                base_url: Some("https://opencode.ai/zen/go".to_string()),
                auth_token: Some("token-a".to_string()),
                api_key: Some("token-b".to_string()),
                ..Default::default()
            },
            auto_updates_channel: "latest".to_string(),
        };

        assert!(settings.normalize_provider_auth());
        assert_eq!(settings.env.api_key.as_deref(), Some("token-b"));
        assert_eq!(settings.env.auth_token.as_deref(), None);
    }

    #[test]
    fn test_native_anthropic() {
        let settings = Settings::native_anthropic("my-api-key".to_string());
        assert!(settings.is_native());
        assert_eq!(settings.env.api_key, Some("my-api-key".to_string()));
    }

    #[test]
    fn test_provider_needs_model_selection() {
        assert!(!ProviderType::MiniMax.needs_model_selection());
        assert!(ProviderType::OpenRouter.needs_model_selection());
        assert!(ProviderType::OpenCodeZen.needs_model_selection());
        assert!(ProviderType::OpenCodeGo.needs_model_selection());
        assert!(!ProviderType::Anthropic.needs_model_selection());
        assert!(!ProviderType::GoogleAI.needs_model_selection());
    }

    #[test]
    fn test_opencode_model_normalization() {
        assert_eq!(ProviderType::OpenCodeZen.normalize_model_id("kimi-k2.5"), "kimi-k2.5");
        assert_eq!(
            ProviderType::OpenCodeZen.normalize_model_id("opencode/kimi-k2.5"),
            "kimi-k2.5"
        );
        assert_eq!(ProviderType::OpenCodeGo.normalize_model_id("kimi-k2.6"), "kimi-k2.6");
        assert_eq!(
            ProviderType::OpenCodeGo.normalize_model_id("opencode-go/kimi-k2.6"),
            "kimi-k2.6"
        );
    }

    #[test]
    fn test_minimax_activation_normalizes_model() {
        let mut settings = Settings::with_base_url(
            "https://api.minimax.io/anthropic".to_string(),
            "my-api-key".to_string(),
            "~moonshotai/kimi-latest".to_string(),
        );

        assert!(settings.normalize_activation_model());
        assert_eq!(settings.model(), Some("MiniMax-M2.7"));
        assert_eq!(settings.env.sonnet_model.as_deref(), Some("MiniMax-M2.7"));
    }
}
