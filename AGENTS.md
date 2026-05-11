# Repository Guidelines

## Idioma

- Preferir Portugues-BR em dialogos, explicacoes, planos e atualizacoes.
- Manter termos tecnicos, nomes de arquivos, APIs, variaveis e erros no idioma original quando fizer sentido.

## Project Structure

Este repositorio agora e centrado no app Rust/Slint em `switch-provider/`.

- `switch-provider/src/main.rs`: ponto de entrada da GUI.
- `switch-provider/ui/appwindow.slint`: interface desktop.
- `switch-provider/src/storage/file_store.rs`: persistencia em `~/.claude`.
- `switch-provider/src/config/settings.rs`: schema do `settings.json`.
- `switch-provider/src/api/openrouter.rs`: cliente HTTP para catalogos OpenRouter/OpenCode.

Scripts Bash/Batch e slash command legado nao fazem mais parte do projeto.

## Build, Test, and Development Commands

```powershell
cd switch-provider
cargo test
cargo run
cargo build --release
```

## Coding Style

- Seguir estilo Rust idiomatico e manter modulos pequenos por responsabilidade.
- Manter UI em Slint simples, com dimensoes estaveis para botoes/listas.
- Evitar expor segredos em logs, mensagens, testes ou docs.
- Preferir recarregar estado real do disco depois de acoes que alterem provider/modelo.

## Testing Guidelines

Depois de mudancas, validar:

- MiniMax -> OpenRouter -> MiniMax sem manter modelo antigo.
- Troca de modelo OpenRouter/OpenCode atualizando `settings.json` e backup ativo.
- Lista e filtro de modelos OpenRouter/OpenCode.
- OpenCode Zen validado em uso real no Claude Code.
- OpenCode Go pendente de validacao com assinatura ativa.
- Janela movida entre dois monitores sem minimizar/sumir.
- Visualizacao de configs com secrets mascarados.
- Cadastro sem NVIDIA.

## Security

Nao commitar `settings.json`, `settings-*.json`, API keys, `.tmp`, `.bak`, binarios ou `target/`.
