//! switch-provider - GUI for managing LLM providers for Claude Code
//! Built with Slint

use slint::Model;
use std::rc::Rc;
use std::sync::Arc;
use switch_provider::{api, config, error, storage};
use tokio::sync::Mutex;

slint::include_modules!();

fn to_provider_model(providers: Vec<config::ProviderInfo>) -> slint::ModelRc<ProviderInfo> {
    let providers = providers
        .iter()
        .map(|provider| ProviderInfo {
            name: provider.name.clone().into(),
            is_active: provider.is_active,
            model: provider.model.clone().unwrap_or_default().into(),
            base_url: provider.base_url.clone().unwrap_or_default().into(),
        })
        .collect::<Vec<_>>();
    Rc::new(slint::VecModel::from(providers)).into()
}

fn to_string_model(values: &[String]) -> slint::ModelRc<slint::SharedString> {
    let values = values
        .iter()
        .map(|value| value.as_str().into())
        .collect::<Vec<_>>();
    Rc::new(slint::VecModel::from(values)).into()
}

fn provider_type_from_index(index: i32) -> Option<config::ProviderType> {
    match index {
        1 => Some(config::ProviderType::MiniMax),
        2 => Some(config::ProviderType::OpenRouter),
        3 => Some(config::ProviderType::Anthropic),
        4 => Some(config::ProviderType::ZAI),
        5 => Some(config::ProviderType::GoogleAI),
        6 => Some(config::ProviderType::OpenAI),
        7 => Some(config::ProviderType::Custom),
        8 => Some(config::ProviderType::OpenCodeZen),
        9 => Some(config::ProviderType::OpenCodeGo),
        10 => Some(config::ProviderType::MaritacaAI),
        _ => None,
    }
}

fn normalize_catalog_models(
    provider_type: config::ProviderType,
    models: Vec<config::Model>,
) -> Vec<String> {
    let mut names = models
        .into_iter()
        .map(|model| provider_type.normalize_model_id(&model.id))
        .filter(|model| is_claude_code_compatible_catalog_model(provider_type, model))
        .collect::<Vec<_>>();
    names.sort();
    names.dedup();
    names
}

fn is_claude_code_compatible_catalog_model(
    provider_type: config::ProviderType,
    model: &str,
) -> bool {
    match provider_type {
        config::ProviderType::OpenCodeZen => !matches!(model, "deepseek-v4-flash-free"),
        _ => true,
    }
}

async fn refresh_app_state(app: &AppWindow, store: &storage::ConfigStore) {
    let providers = store.list_providers().await.unwrap_or_default();
    app.set_providers(to_provider_model(providers));

    let current_provider = store
        .get_current_provider_name()
        .await
        .ok()
        .flatten()
        .unwrap_or_else(|| "Nenhum".to_string());
    app.set_current_provider(current_provider.into());

    let active_settings = store.read_active().await.ok().flatten();
    let current_model = active_settings
        .as_ref()
        .and_then(|settings| settings.model().map(|model| model.to_string()))
        .unwrap_or_default();
    let can_change_model = active_settings
        .as_ref()
        .and_then(|settings| settings.provider_type())
        .map(|provider_type| provider_type.needs_model_selection())
        .unwrap_or(false);

    app.set_current_model(current_model.into());
    app.set_can_change_model(can_change_model);
}

fn filter_models(models: &[String], filter: &str) -> Vec<String> {
    let filter = filter.trim().to_lowercase();
    if filter.is_empty() {
        return models.to_vec();
    }

    models
        .iter()
        .filter(|model| model.to_lowercase().contains(&filter))
        .cloned()
        .collect()
}

fn mask_settings_json(settings: &config::Settings) -> String {
    let mut value = serde_json::to_value(settings).unwrap_or_default();
    mask_secret_values(&mut value);
    serde_json::to_string_pretty(&value).unwrap_or_default()
}

fn mask_secret_values(value: &mut serde_json::Value) {
    match value {
        serde_json::Value::Object(map) => {
            for (key, value) in map.iter_mut() {
                if key.contains("TOKEN") || key.contains("KEY") {
                    if let Some(secret) = value.as_str() {
                        *value = serde_json::Value::String(error::mask_api_key(secret));
                    }
                } else {
                    mask_secret_values(value);
                }
            }
        }
        serde_json::Value::Array(items) => {
            for item in items {
                mask_secret_values(item);
            }
        }
        _ => {}
    }
}

fn provider_name_from_index(app: &AppWindow, index: i32) -> Option<String> {
    app.get_providers()
        .iter()
        .enumerate()
        .find(|(current_index, _)| *current_index == index as usize)
        .map(|(_, provider)| provider.name.to_string())
        .filter(|name| !name.is_empty())
}

fn main() -> Result<(), slint::PlatformError> {
    if std::env::var_os("SLINT_BACKEND").is_none() {
        std::env::set_var("SLINT_BACKEND", "software");
    }

    #[cfg(windows)]
    {
        use windows::Win32::System::Console::FreeConsole;
        unsafe {
            let _ = FreeConsole();
        }
    }

    let runtime = Arc::new(
        tokio::runtime::Builder::new_multi_thread()
            .enable_all()
            .build()
            .expect("failed to create tokio runtime"),
    );

    let app = AppWindow::new()?;
    let config_store = Arc::new(Mutex::new(
        runtime
            .block_on(async { storage::ConfigStore::new().await })
            .expect("failed to create config store"),
    ));

    runtime.block_on(async {
        let store = config_store.lock().await;
        refresh_app_state(&app, &store).await;
    });

    let config_store_clone = config_store.clone();
    let app_handle = app.as_weak();
    let runtime_clone = runtime.clone();

    app.on_on_select_provider(move |index| {
        let store = config_store_clone.clone();
        let app = app_handle.unwrap();
        let Some(name) = provider_name_from_index(&app, index) else {
            return;
        };

        app.set_is_loading(true);
        app.set_status_message("Ativando provider...".into());

        runtime_clone.block_on(async {
            let store = store.lock().await;
            match store.activate(&name).await {
                Ok(()) => app.set_status_message(format!("Provider ativo: {name}").into()),
                Err(error) => app.set_status_message(format!("Erro: {error}").into()),
            }
            refresh_app_state(&app, &store).await;
            app.set_selected_index(-1);
            app.set_is_loading(false);
        });
    });

    let config_store_clone = config_store.clone();
    let app_handle = app.as_weak();
    let runtime_clone = runtime.clone();

    app.on_on_add_provider(move |endpoint, name, api_key, selected_model| {
        let store = config_store_clone.clone();
        let app = app_handle.unwrap();

        if name.trim().is_empty() || api_key.trim().is_empty() {
            return;
        }

        app.set_is_loading(true);
        app.set_status_message("Salvando provider...".into());

        runtime_clone.block_on(async move {
            use crate::config::{ProviderType, Settings};

            let Some(provider_type) = provider_type_from_index(endpoint as i32) else {
                return;
            };

            let mut default_model = provider_type
                .default_model()
                .unwrap_or("claude-sonnet-4-20250514")
                .to_string();
            if provider_type.needs_model_selection() && !selected_model.trim().is_empty() {
                default_model = provider_type.normalize_model_id(&selected_model);
            }
            let settings = if provider_type == ProviderType::Anthropic {
                Settings::native_anthropic(api_key.to_string())
            } else if let Some(base_url) = provider_type.endpoint() {
                Settings::with_base_url(base_url.to_string(), api_key.to_string(), default_model)
            } else {
                Settings::with_base_url("custom".to_string(), api_key.to_string(), default_model)
            };

            let store = store.lock().await;
            let result = match store.save_provider(&name, &settings).await {
                Ok(()) => store.activate(&name).await,
                Err(error) => Err(error),
            };

            match result {
                Ok(()) => app.set_status_message(format!("Provider salvo e ativo: {name}").into()),
                Err(error) => app.set_status_message(format!("Erro: {error}").into()),
            }
            refresh_app_state(&app, &store).await;
            app.set_selected_index(-1);
            app.set_is_loading(false);
        });
    });

    let config_store_clone = config_store.clone();
    let app_handle = app.as_weak();
    let runtime_clone = runtime.clone();

    app.on_on_remove_provider(move |index| {
        let store = config_store_clone.clone();
        let app = app_handle.unwrap();
        let Some(name) = provider_name_from_index(&app, index) else {
            return;
        };

        app.set_is_loading(true);
        app.set_status_message("Removendo provider...".into());

        runtime_clone.block_on(async {
            let store = store.lock().await;
            match store.delete_provider(&name).await {
                Ok(()) => app.set_status_message("Provider removido.".into()),
                Err(error) => app.set_status_message(format!("Erro: {error}").into()),
            }
            refresh_app_state(&app, &store).await;
            app.set_is_loading(false);
        });
    });

    let config_store_clone = config_store.clone();
    let app_handle = app.as_weak();
    let runtime_clone = runtime.clone();

    app.on_on_rename_provider(move |index, new_name| {
        let store = config_store_clone.clone();
        let app = app_handle.unwrap();
        let Some(old_name) = provider_name_from_index(&app, index) else {
            return;
        };

        if new_name.trim().is_empty() {
            return;
        }

        app.set_is_loading(true);
        app.set_status_message("Renomeando provider...".into());

        runtime_clone.block_on(async {
            let store = store.lock().await;
            match store.rename_provider(&old_name, &new_name).await {
                Ok(()) => app.set_status_message("Provider renomeado.".into()),
                Err(error) => app.set_status_message(format!("Erro: {error}").into()),
            }
            refresh_app_state(&app, &store).await;
            app.set_is_loading(false);
        });
    });

    let config_store_clone = config_store.clone();
    let app_handle = app.as_weak();
    let runtime_clone = runtime.clone();

    app.on_on_view_settings(move || {
        let store = config_store_clone.clone();
        let app = app_handle.unwrap();

        app.set_is_loading(true);
        app.set_status_message("Carregando configuracoes...".into());

        runtime_clone.block_on(async {
            let store = store.lock().await;
            let provider = store
                .get_current_provider_name()
                .await
                .ok()
                .flatten()
                .unwrap_or_else(|| "Nenhum".to_string());
            let path = store.active_settings_path().display().to_string();

            match store.read_active().await {
                Ok(Some(settings)) => {
                    let model = settings.model().unwrap_or("(sem modelo)");
                    let json = mask_settings_json(&settings);
                    app.set_settings_json(
                        format!("Arquivo: {path}\nProvider detectado: {provider}\nModelo ativo: {model}\n\n{json}")
                            .into(),
                    );
                    app.set_status_message("Configuracoes carregadas.".into());
                }
                Ok(None) => {
                    app.set_settings_json(format!("Arquivo: {path}\n\nNenhum settings.json ativo.").into());
                    app.set_status_message("Nenhum settings.json ativo.".into());
                }
                Err(error) => {
                    app.set_settings_json(format!("Erro ao ler {path}: {error}").into());
                    app.set_status_message(format!("Erro: {error}").into());
                }
            }

            app.set_is_loading(false);
            app.set_show_view_settings(true);
        });
    });

    let config_store_clone = config_store.clone();
    let app_handle = app.as_weak();
    let runtime_clone = runtime.clone();

    app.on_on_change_model(move |model_name| {
        let store = config_store_clone.clone();
        let app = app_handle.unwrap();

        if model_name.trim().is_empty() {
            return;
        }

        app.set_is_loading(true);
        app.set_status_message("Alterando modelo...".into());

        runtime_clone.block_on(async {
            let store = store.lock().await;
            match store.update_active_catalog_model(&model_name).await {
                Ok(()) => app.set_status_message("Modelo alterado.".into()),
                Err(error) => app.set_status_message(format!("Erro: {error}").into()),
            }
            refresh_app_state(&app, &store).await;
            app.set_is_loading(false);
            app.set_show_change_model(false);
        });
    });

    let config_store_clone = config_store.clone();
    let app_handle = app.as_weak();
    let runtime_clone = runtime.clone();

    app.on_on_load_models(move || {
        let store = config_store_clone.clone();
        let app = app_handle.unwrap();

        app.set_is_loading(true);
        app.set_status_message("Carregando modelos...".into());

        runtime_clone.block_on(async {
            let store = store.lock().await;
            match store.read_active().await {
                Ok(Some(settings)) => {
                    let Some(provider_type) = settings.provider_type() else {
                        app.set_status_message("Provider ativo sem tipo reconhecido.".into());
                        app.set_is_loading(false);
                        return;
                    };
                    let Some(model_list_url) = provider_type.model_list_url() else {
                        app.set_status_message(
                            "Troca dinamica disponivel apenas para providers com catalogo de modelos."
                                .into(),
                        );
                        app.set_is_loading(false);
                        return;
                    };
                    let api_key = settings
                        .env
                        .auth_token
                        .as_deref()
                        .or(settings.env.api_key.as_deref())
                        .unwrap_or("");

                    let client = api::OpenRouterClient::new();
                    match client.list_models_from(model_list_url, api_key).await {
                        Ok(models) => {
                            let names = normalize_catalog_models(provider_type, models);
                            let filtered = filter_models(&names, &app.get_model_filter());
                            app.set_available_models(to_string_model(&names));
                            app.set_filtered_models(to_string_model(&filtered));
                            app.set_model_selected_index(-1);
                            app.set_status_message(
                                format!(
                                    "{} modelos {} carregados.",
                                    names.len(),
                                    provider_type.display_name()
                                )
                                .into(),
                            );
                        }
                        Err(error) => {
                            app.set_status_message(
                                format!("Erro ao carregar modelos: {error}").into(),
                            );
                        }
                    }
                }
                Ok(None) => {
                    app.set_status_message("Nenhum provider ativo.".into());
                }
                Err(error) => {
                    app.set_status_message(format!("Erro: {error}").into());
                }
            }

            app.set_is_loading(false);
        });
    });

    let app_handle = app.as_weak();
    let runtime_clone = runtime.clone();

    app.on_on_load_new_provider_models(move |endpoint, api_key| {
        let app = app_handle.unwrap();

        let Some(provider_type) = provider_type_from_index(endpoint as i32) else {
            app.set_status_message("Provider invalido.".into());
            return;
        };
        let Some(model_list_url) = provider_type.model_list_url() else {
            app.set_status_message("Este provider nao possui catalogo de modelos.".into());
            return;
        };

        app.set_is_loading(true);
        app.set_status_message(format!("Carregando modelos {}...", provider_type.display_name()).into());

        runtime_clone.block_on(async {
            let client = api::OpenRouterClient::new();
            match client.list_models_from(model_list_url, &api_key).await {
                Ok(models) => {
                    let names = normalize_catalog_models(provider_type, models);
                    let filtered = filter_models(&names, &app.get_model_filter());
                    app.set_available_models(to_string_model(&names));
                    app.set_filtered_models(to_string_model(&filtered));
                    app.set_model_selected_index(-1);
                    app.set_status_message(
                        format!("{} modelos {} carregados.", names.len(), provider_type.display_name()).into(),
                    );
                }
                Err(error) => {
                    app.set_status_message(
                        format!("Erro ao carregar modelos: {error}").into(),
                    );
                }
            }
            app.set_is_loading(false);
        });
    });

    let app_handle = app.as_weak();
    app.on_on_filter_models(move |filter| {
        let app = app_handle.unwrap();
        let models = app
            .get_available_models()
            .iter()
            .map(|model| model.to_string())
            .collect::<Vec<_>>();
        let filtered = filter_models(&models, &filter);
        app.set_filtered_models(to_string_model(&filtered));
        app.set_model_selected_index(-1);
    });

    app.on_on_claude_login(move || {
        if let Err(error) = std::process::Command::new("claude").arg("login").spawn() {
            eprintln!("Error starting claude login: {error}");
        }
    });

    app.on_on_exit(move || {
        std::process::exit(0);
    });

    app.run()
}
