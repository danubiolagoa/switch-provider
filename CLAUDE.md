# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Projeto

**switch-provider-v1** — Script para gerenciar e alternar entre múltiplos providers de LLM no Claude Code (MiniMax, OpenRouter, Z.AI/GLM, Anthropic, Google AI Studio, OpenAI e endpoints customizados).

---

## Comandos comuns

### Scripts interativos
```bash
# Linux/Mac
chmod +x claude-switch.sh && ./claude-switch.sh

# Windows
claude-switch.bat
```

### Slash command dentro do Claude Code
```
/switch-provider
```

---

## Arquitetura

### Persistência de providers

O Claude Code lê `~/.claude/settings.json` na inicialização. O switch-provider mantém backups nomeados:

```
~/.claude/
├── settings.json              ← ativo no momento
├── settings-minimax.json      ← backup MiniMax
├── settings-openrouter.json   ← backup OpenRouter
├── settings-glm.json          ← backup GLM
└── commands/
    └── switch-provider.md     ← slash command
```

**Ao alternar**: o script copia o arquivo `settings-NOME.json` escolhido para `~/.claude/settings.json`.

**Importante**: Após alternar provider, é necessário **reiniciar o Claude Code** para aplicar as mudanças.

### Arquivos do projeto

| Arquivo | Descrição |
|---------|-----------|
| `claude-switch.sh` | Script Bash — Linux/Mac |
| `claude-switch.bat` | Script Batch — Windows |
| `.claude/commands/switch-provider.md` | Slash command `/switch-provider` para uso dentro do Claude Code |

### Fluxo de adicionar provider

1. Escolher endpoint (MiniMax, OpenRouter, Anthropic, Z.AI/GLM, Google AI Studio, OpenAI, Custom)
2. Informar nome do provider
3. Informar API Key
4. Para OpenRouter/Google AI Studio/OpenAI/Custom: selecionar modelos por slot
5. Confirmar todos os modelos antes de salvar
6. Opcional: ativar imediatamente

### Seleção de modelos por slot

Método organizado para preenchimento:
- **Opção A**: Colar lista formatada (`principal:modelo`, uma por linha)
- **Opção B**: Preencher um por um (ENTER para pular)

Slots disponíveis:
| Slot | Variável | Descrição |
|------|----------|-----------|
| Principal | `ANTHROPIC_MODEL` | Modelo padrão geral |
| Rápido | `ANTHROPIC_SMALL_FAST_MODEL` | Tarefas simples |
| Sonnet | `ANTHROPIC_DEFAULT_SONNET_MODEL` | Tarefas intermediárias |
| Opus | `ANTHROPIC_DEFAULT_OPUS_MODEL` | Tarefas complexas |
| Haiku | `ANTHROPIC_DEFAULT_HAIKU_MODEL` | Tarefas leves |

### Providers pré-configurados

| Provider | Endpoint | Modelo default |
|----------|----------|----------------|
| MiniMax | `https://api.minimax.io/anthropic` | `MiniMax-M2.7` |
| OpenRouter | `https://openrouter.ai/api` | buscar da API |
| Z.AI/GLM | `https://api.z.ai/api/anthropic` | `GLM-4.7` |
| Anthropic | *(nativo)* | `claude-sonnet-4-20250514` |
| Google AI Studio | `https://generativelanguage.googleapis.com` | `gemini-2.0-flash` |
| OpenAI | `https://api.openai.com/v1` | `gpt-4o-mini` |
| Custom | qualquer endpoint | definido pelo usuário |

### Configuração do settings.json

**Com BASE_URL** (non-Anthropic):
```json
{
  "env": {
    "ANTHROPIC_BASE_URL": "ENDPOINT",
    "ANTHROPIC_AUTH_TOKEN": "API_KEY",
    "ANTHROPIC_API_KEY": "",
    "API_TIMEOUT_MS": "3000000",
    "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC": "1",
    "ANTHROPIC_MODEL": "MODELO_PRINCIPAL",
    "ANTHROPIC_SMALL_FAST_MODEL": "MODELO_RAPIDO",
    "ANTHROPIC_DEFAULT_SONNET_MODEL": "MODELO_SONNET",
    "ANTHROPIC_DEFAULT_OPUS_MODEL": "MODELO_OPUS",
    "ANTHROPIC_DEFAULT_HAIKU_MODEL": "MODELO_HAIKU"
  },
  "autoUpdatesChannel": "latest"
}
```

**Anthropic nativo**:
```json
{
  "env": {
    "ANTHROPIC_API_KEY": "API_KEY",
    "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC": "1"
  },
  "autoUpdatesChannel": "latest"
}
```

---

## Instalação

1. Copiar o slash command:
   ```bash
   # Linux/Mac
   mkdir -p ~/.claude/commands
   cp .claude/commands/switch-provider.md ~/.claude/commands/

   # Windows (PowerShell)
   New-Item -ItemType Directory -Force "$HOME\.claude\commands"
   Copy-Item ".claude/commands\switch-provider.md" "$HOME\.claude\commands\"
   ```

2. Usar o script interativo para o primeiro setup:
   - Windows: executar `claude-switch.bat`
   - Linux/Mac: `./claude-switch.sh`

> **Nota**: O slash command `/switch-provider` só funciona depois que o Claude Code já está rodando com um provider válido. O script é necessário para o primeiro setup.
