# Claude Provider Manager

**Current version: 1.0.1**

Manage and switch between multiple LLM providers in **Claude Code** — MiniMax, OpenRouter, Z.AI/GLM, Anthropic, and any API-compatible endpoint.

---

## Why does this exist?

Claude Code only supports one provider at a time via `~/.claude/settings.json`. This command is part of **switch-provider** — an open source project to manage multiple LLM providers in Claude Code.

- **Interactive script** for initial setup and quick switching (Windows and Linux/Mac)
- **Slash command `/switch-provider`** to switch from inside Claude Code, without leaving the terminal

---

## Repository structure

```
switch-provider-v1/
├── README.md
├── README-en.md
├── LICENSE
├── .gitignore
├── claude-switch.bat          # Interactive script — Windows
├── claude-switch.sh           # Interactive script — Linux/Mac
└── .claude/
    └── commands/
        └── switch-provider.md # Slash command for Claude Code
```

---

## Installation

### 1. Clone the repository

```bash
git clone https://github.com/YOUR_USER/switch-provider.git
cd switch-provider
```

### 2. Copy the slash command to Claude Code's folder

**Linux/Mac:**
```bash
mkdir -p ~/.claude/commands
cp .claude/commands/switch-provider.md ~/.claude/commands/
```

**Windows (PowerShell):**
```powershell
New-Item -ItemType Directory -Force "$HOME\.claude\commands"
Copy-Item ".claude\commands\switch-provider.md" "$HOME\.claude\commands\"
```

### 3. Configure your first provider with the script

> ⚠️ The `/switch-provider` slash command only works after Claude Code is already running with a valid provider. Use the script below for the **first setup**.

**Windows** — run the file directly:
```
claude-switch.bat
```

**Linux/Mac** — give permission and run:
```bash
chmod +x claude-switch.sh
./claude-switch.sh
```

The script will guide you to configure your first provider and generate the correct `settings.json`.

---

## Usage

### Via script (outside Claude Code)

Run `claude-switch.bat` (Windows) or `./claude-switch.sh` (Linux/Mac) anytime to:

- Switch between already configured providers
- Add a new provider
- Remove a provider
- View which provider is currently active

### Via slash command (inside Claude Code)

With Claude Code running, type:

```
/switch-provider
```

Claude will list your available providers and guide you through the interactive switch.

---

## Supported providers

| Provider | Endpoint | Notes |
|---|---|---|
| **MiniMax** | `https://api.minimax.io/anthropic` | International users |
| **OpenRouter** | `https://openrouter.ai/api` | Access to dozens of models |
| **Z.AI / GLM** | `https://api.z.ai/api/anthropic` | GLM models from Zhipu AI |
| **Anthropic** | *(native)* | Uses `ANTHROPIC_API_KEY` directly |
| **Google AI Studio** | `https://generativelanguage.googleapis.com` | Gemini models |
| **OpenAI** | `https://api.openai.com/v1` | GPT models |
| **Custom** | Any compatible endpoint | Enter manually |

---

## How it works

Claude Code reads `~/.claude/settings.json` at each startup. This project keeps backup files named `settings-NAME.json` and copies the chosen one as `settings.json` when switching.

```
~/.claude/
├── settings.json              ← currently active
├── settings-minimax.json      ← MiniMax backup
├── settings-openrouter.json   ← OpenRouter backup
├── settings-glm.json          ← GLM backup
└── commands/
    └── switch-provider.md     ← slash command
```

---

## Contributing

Pull requests are welcome! Suggestions for new pre-configured providers, script improvements, or support for new platforms are especially appreciated.

---

## License

MIT
