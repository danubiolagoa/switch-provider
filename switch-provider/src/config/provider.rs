use serde::{Deserialize, Serialize};
use std::path::PathBuf;

/// Information about a saved provider
#[derive(Serialize, Deserialize, Debug, Clone)]
pub struct ProviderInfo {
    /// The provider name (settings-NAME.json)
    pub name: String,
    /// Full path to the settings file
    pub path: PathBuf,
    /// Whether this is the currently active provider
    pub is_active: bool,
    /// The configured model (if known)
    pub model: Option<String>,
    /// The configured Anthropic-compatible base URL (if known)
    pub base_url: Option<String>,
}

impl ProviderInfo {
    /// Get the file name without extension (e.g., "settings-minimax" -> "minimax")
    pub fn name_from_path(path: &PathBuf) -> Option<String> {
        path.file_stem()
            .and_then(|s| s.to_str())
            .map(|s| s.replace("settings-", ""))
    }
}

/// Model information from API
#[derive(Debug, Clone)]
pub struct Model {
    /// Model ID (e.g., "anthropic/claude-3.5-sonnet")
    pub id: String,
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_name_from_path() {
        let path = PathBuf::from("settings-minimax.json");
        assert_eq!(
            ProviderInfo::name_from_path(&path),
            Some("minimax".to_string())
        );

        let path = PathBuf::from("settings-openrouter.json");
        assert_eq!(
            ProviderInfo::name_from_path(&path),
            Some("openrouter".to_string())
        );
    }
}
