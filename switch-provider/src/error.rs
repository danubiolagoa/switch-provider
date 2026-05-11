use anyhow::Result;
use std::path::PathBuf;
use thiserror::Error;

#[derive(Error, Debug)]
pub enum AppError {
    #[error("Config directory not found")]
    ConfigDirNotFound,

    #[error("Failed to read config directory: {0}")]
    ConfigDir(#[from] std::io::Error),

    #[error("Invalid settings file '{0}': {1}")]
    InvalidSettings(String, String),

    #[error("Provider not found: {0}")]
    ProviderNotFound(String),

    #[error("Provider already exists: {0}")]
    ProviderAlreadyExists(String),

    #[error("API error: {0}")]
    ApiError(String),

    #[error("Network error: {0}")]
    NetworkError(String),

    #[error("Invalid API key")]
    InvalidApiKey,

    #[error("User cancelled")]
    Cancelled,

    #[error("JSON error: {0}")]
    JsonError(#[from] serde_json::Error),
}

pub type AppResult<T> = Result<T, AppError>;

/// Get the config directory path (~/.claude)
pub fn get_config_dir() -> AppResult<PathBuf> {
    dirs::home_dir()
        .map(|p| p.join(".claude"))
        .ok_or(AppError::ConfigDirNotFound)
}

/// Mask an API key for display (show first 4 chars + asterisks)
pub fn mask_api_key(key: &str) -> String {
    if key.len() <= 4 {
        "*".repeat(key.len())
    } else {
        format!("{}****************************", &key[..4.min(key.len())])
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_mask_api_key() {
        assert_eq!(mask_api_key("abc"), "***");
        assert_eq!(mask_api_key("abcd"), "****");
        assert_eq!(mask_api_key("abcdef"), "abcd****************************");
        assert_eq!(mask_api_key(""), "");
    }
}
