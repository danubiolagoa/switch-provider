# Switch Provider

Rust/Slint desktop app for managing LLM providers used by Claude Code.

Claude Code reads one active file at `~/.claude/settings.json`. Switch Provider keeps named backups such as `settings-minimax.json`, `settings-openrouter.json`, and other `settings-NAME.json` files so the active provider can be changed without manual JSON editing.

## Features

- Desktop UI to add, activate, rename, and remove providers.
- Supported providers: MiniMax, OpenRouter, OpenCode Zen, OpenCode Go, Anthropic, Z.AI/GLM, Google AI, OpenAI, and Custom.
- Dynamic model switching for OpenRouter, OpenCode Zen, and OpenCode Go, including fresh API model loading and UI filtering.
- OpenCode Zen has been validated in real Claude Code usage. Its catalog uses raw IDs, such as `kimi-k2.5`, without `opencode/` prefixes.
- OpenCode Go is available as a separate provider and requires an active OpenCode Go subscription.
- OpenCode Zen models that are incompatible with Claude Code tools/function calling can be hidden from the list, such as `deepseek-v4-flash-free`.
- Safe `settings.json` viewer with API keys and tokens masked.
- API keys are hidden after model loading in the provider setup flow.
- Temporary-file write plus `.bak` backup to reduce settings corruption risk.
- The window defaults to Slint's `software` renderer and a minimum size to reduce monitor/DPI move glitches.

## Install

### Windows (available)

Download the `.exe` installer from GitHub Releases and open it with a double click:

```text
switch-provider_1.0.3_x64-setup.exe
```

After installation, open Switch Provider from the Start Menu.

Via PowerShell:

```powershell
irm https://raw.githubusercontent.com/danubiolagoa/switch-provider/main/install/install.ps1 | iex
```

### Linux and macOS

Linux and macOS are still under validation. There are separate issues to generate and test `.deb`/`.AppImage` on Linux and `.app`/`.dmg` on macOS before publishing those downloads as official.

Winget is also planned for a later step.

## Run for development

```powershell
cd switch-provider
cargo run
```

Release build:

```powershell
cd switch-provider
cargo build --release
```

Generated executable:

```text
switch-provider/target/release/switch-provider.exe
```

Generate the Windows installer locally:

```powershell
cd switch-provider
npx --yes @crabnebula/packager --config Packager.toml --formats nsis
```

The NSIS installer is generated in `dist/`. See `.docs/instalador-windows.md` for the QA checklist.

## Configuration

Files live in `~/.claude`:

```text
~/.claude/
├── settings.json
├── settings-minimax.json
├── settings-openrouter.json
└── settings-other-provider.json
```

When a provider is activated, the app reads the matching backup and writes it into `settings.json`.

## Security

Do not commit `settings.json`, `settings-*.json`, API keys, generated binaries, or `target/` contents. The `.gitignore` covers these cases.

Installers do not include local API keys or `settings*.json` files; each user configures their own providers after installation.

## Development

```powershell
cd switch-provider
cargo test
cargo build --release
```

Before publishing changes, validate:

- switching MiniMax -> OpenRouter -> MiniMax;
- changing OpenRouter/OpenCode Zen models and confirming both `settings.json` and `settings-NAME.json` are updated;
- confirming OpenCode Zen works in Claude Code with a gateway-supported model;
- confirming `Mudar modelo` refreshes the live catalog and excludes blocked models such as `deepseek-v4-flash-free`;
- opening "Ver configs" and confirming secrets are masked;
- moving the window between two monitors and confirming it does not minimize/disappear;
- adding a provider and confirming NVIDIA is not listed.
