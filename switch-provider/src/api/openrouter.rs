use crate::config::provider::Model;
use crate::error::{AppError, AppResult};
use reqwest::Client;
use std::time::Duration;

/// OpenRouter API client
pub struct OpenRouterClient {
    http: Client,
}

impl OpenRouterClient {
    pub fn new() -> Self {
        let http = Client::builder()
            .timeout(Duration::from_secs(30))
            .build()
            .expect("Failed to create HTTP client");
        Self { http }
    }

    /// List models from OpenRouter
    pub async fn list_models(&self, api_key: &str) -> AppResult<Vec<Model>> {
        self.list_models_from("https://openrouter.ai/api/v1/models", api_key)
            .await
    }

    /// List models from a compatible provider catalog endpoint.
    pub async fn list_models_from(&self, url: &str, api_key: &str) -> AppResult<Vec<Model>> {
        let mut request = self.http.get(url);
        if !api_key.trim().is_empty() {
            request = request.header("Authorization", format!("Bearer {}", api_key));
        }

        let response = request
            .send()
            .await
            .map_err(|e| AppError::NetworkError(e.to_string()))?;

        if !response.status().is_success() {
            let status = response.status();
            let text = response.text().await.unwrap_or_default();
            return Err(AppError::ApiError(format!("Status {}: {}", status, text)));
        }

        #[derive(serde::Deserialize)]
        struct Response {
            data: Vec<ModelData>,
        }

        #[derive(serde::Deserialize)]
        struct ModelData {
            id: String,
        }

        let response: Response = response
            .json()
            .await
            .map_err(|e| AppError::ApiError(format!("Failed to parse response: {}", e)))?;

        let models: Vec<Model> = response
            .data
            .into_iter()
            .map(|m| Model { id: m.id })
            .collect();

        Ok(models)
    }

    /// Validate an OpenRouter API key
    pub async fn validate_key(&self, api_key: &str) -> AppResult<bool> {
        let response = self
            .http
            .get("https://openrouter.ai/api/v1/key")
            .header("Authorization", format!("Bearer {}", api_key))
            .send()
            .await
            .map_err(|e| AppError::NetworkError(e.to_string()))?;

        Ok(response.status().is_success())
    }
}

impl Default for OpenRouterClient {
    fn default() -> Self {
        Self::new()
    }
}
