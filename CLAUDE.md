# Switch Provider - notas do projeto

Este projeto agora e um aplicativo desktop em Rust com Slint. A implementacao antiga em Bash/Batch e o slash command legado foram removidos.

## Arquitetura atual

```text
switch-provider/
├── Cargo.toml
├── build.rs
├── ui/appwindow.slint
└── src/
    ├── main.rs
    ├── api/openrouter.rs
    ├── config/
    ├── storage/
    └── error.rs
```

- `src/main.rs`: integra callbacks da UI com storage e API.
- `ui/appwindow.slint`: layout desktop.
- `src/storage/file_store.rs`: leitura/escrita de `~/.claude/settings.json` e `settings-*.json`.
- `src/config/settings.rs`: estrutura do JSON esperado pelo Claude Code.
- `src/api/openrouter.rs`: cliente HTTP usado para carregar catalogos de modelos OpenRouter/OpenCode.

## Comandos

```powershell
cd switch-provider
cargo test
cargo run
cargo build --release
```

## Regras de seguranca

- Nunca imprimir ou commitar API keys.
- Nunca commitar `settings.json`, `settings-*.json`, `.bak`, `.tmp`, `target/`, `.exe` ou `.pdb`.
- Ao alterar modelo OpenRouter/OpenCode, manter `settings.json` e o backup ativo sincronizados.
- Ao alternar provider, sempre recarregar estado a partir do disco.
- OpenCode Zen usa IDs crus do catalogo, como `kimi-k2.5`, sem prefixos `opencode/`.
- OpenCode Go requer assinatura OpenCode Go ativa.
- API keys devem ficar mascaradas/ocultas depois do carregamento de modelos.

## Providers

Providers suportados no fluxo de cadastro: MiniMax, OpenRouter, OpenCode Zen, OpenCode Go, Anthropic, Z.AI/GLM, Google AI, OpenAI e Custom.

A troca dinamica de modelos cobre OpenRouter, OpenCode Zen e OpenCode Go. OpenCode Zen ja foi validado em uso real no Claude Code; OpenCode Go ainda depende de validacao com assinatura ativa.

## QA manual antes de empacotar

- Confirmar OpenCode Zen ativo e funcional no Claude Code.
- Confirmar que `Mudar modelo` recarrega o catalogo atual e nao exibe `deepseek-v4-flash-free`.
- Confirmar `Ver configs` com segredos mascarados.
- Mover a janela entre dois monitores e verificar que ela nao minimiza/some.
- Repetir secret scan antes de publicar/taguear.
