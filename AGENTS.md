# Repository Guidelines

## Project Structure & Module Organization
This repository is intentionally small and script-focused. The main entry points are [`claude-switch.sh`](/C:/Users/danub/códigos/switch-provider-v1/claude-switch.sh) for Linux/Mac and [`claude-switch.bat`](/C:/Users/danub/códigos/switch-provider-v1/claude-switch.bat) for Windows. The Claude Code slash command lives at [`.claude/commands/switch-provider.md`](/C:/Users/danub/códigos/switch-provider-v1/.claude/commands/switch-provider.md). Project documentation is in [`README.md`](/C:/Users/danub/códigos/switch-provider-v1/README.md), and [`CLAUDE.md`](/C:/Users/danub/códigos/switch-provider-v1/CLAUDE.md) captures behavior and architecture notes for AI-assisted edits.

## Build, Test, and Development Commands
There is no build step or package manager in this repo. Use the scripts directly:

- `./claude-switch.sh`: run the interactive provider manager on Linux/Mac.
- `chmod +x claude-switch.sh`: make the shell script executable before first run.
- `claude-switch.bat`: run the interactive provider manager on Windows.
- `cp .claude/commands/switch-provider.md ~/.claude/commands/`: install the slash command on Linux/Mac.
- `Copy-Item ".claude\\commands\\switch-provider.md" "$HOME\\.claude\\commands\\"`: install the slash command on Windows PowerShell.

## Coding Style & Naming Conventions
Keep shell code POSIX-friendly where practical and preserve the current procedural style. Use 4-space indentation in Bash functions and consistent uppercase variable names for environment-driven values such as `CONFIG_DIR` and `SETTINGS`. In Batch files, keep labels short and uppercase, such as `:MENU` and `:ATIVAR`. File names should remain descriptive and kebab-case or tool-native, matching the existing pattern: `claude-switch.sh`, `switch-provider.md`.

## Testing Guidelines
This project currently relies on manual validation. After changes, test both the happy path and failure cases:

- Add, activate, view, and remove a provider.
- Confirm `~/.claude/settings.json` is updated correctly.
- Verify the script returns to the menu after each action.
- Confirm the slash command instructions still match actual script behavior.

When possible, test the changed platform directly: Bash changes on Linux/Mac, Batch changes on Windows.

## Commit & Pull Request Guidelines
Git history is minimal, with short Portuguese messages such as `Commit Inicial`. Keep commits concise, imperative, and focused on one change, for example: `Adiciona suporte ao provider OpenAI`. Pull requests should include a clear summary, affected platforms, manual test notes, and screenshots or terminal snippets when UI text or menus change.

## Security & Configuration Tips
Do not commit real API keys, populated `settings.json` files, or local secrets from `~/.claude`. Any example config should use placeholders only.
