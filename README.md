# Claude Provider Manager

**Versão atual: 1.0.1**

Gerencie e alterne entre múltiplos providers de LLM no **Claude Code** — MiniMax, OpenRouter, Z.AI/GLM, Anthropic e qualquer endpoint compatível com a API da Anthropic.

---

## Por que isso existe?

O Claude Code só suporta um provider por vez via `~/.claude/settings.json`. Este comando faz parte do **switch-provider** — projeto open source para gerenciar múltiplos providers de LLM no Claude Code.

- **Script interativo** para primeiro setup e alternância rápida (Windows e Linux/Mac)
- **Slash command `/switch-provider`** para alternar de dentro do próprio Claude Code, sem sair do terminal

---

## Estrutura do repositório

```
switch-provider-v1/
├── README.md
├── LICENSE
├── .gitignore
├── claude-switch.bat          # Script interativo — Windows
├── claude-switch.sh           # Script interativo — Linux/Mac
└── .claude/
    └── commands/
        └── switch-provider.md # Slash command para o Claude Code
```

---

## Instalação

### 1. Clone o repositório

```bash
git clone https://github.com/SEU_USUARIO/switch-provider.git
cd switch-provider
```

### 2. Copie o slash command para a pasta do Claude Code

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

### 3. Configure o primeiro provider com o script

> ⚠️ O slash command `/switch-provider` só funciona depois que o Claude Code já está rodando com um provider válido. Use o script abaixo para o **primeiro setup**.

**Windows** — execute o arquivo diretamente:
```
claude-switch.bat
```

**Linux/Mac** — dê permissão e execute:
```bash
chmod +x claude-switch.sh
./claude-switch.sh
```

O script vai guiar você para configurar o primeiro provider e gerar o `settings.json` correto.

---

## Uso

### Via script (fora do Claude Code)

Execute `claude-switch.bat` (Windows) ou `./claude-switch.sh` (Linux/Mac) a qualquer momento para:

- Alternar entre providers já configurados
- Adicionar um novo provider
- Remover um provider
- Ver qual provider está ativo

### Via slash command (dentro do Claude Code)

Com o Claude Code rodando, digite:

```
/switch-provider
```

O Claude vai listar seus providers disponíveis e guiar a alternância interativamente.

---

## Providers suportados

| Provider | Endpoint | Notas |
|---|---|---|
| **MiniMax** | `https://api.minimax.io/anthropic` | Usuários internacionais |
| **OpenRouter** | `https://openrouter.ai/api` | Acesso a dezenas de modelos |
| **Z.AI / GLM** | `https://api.z.ai/api/anthropic` | Modelos GLM da Zhipu AI |
| **Anthropic** | *(nativo)* | Usa `ANTHROPIC_API_KEY` diretamente |
| **Custom** | Qualquer endpoint compatível | Digite manualmente |

---

## Como funciona

O Claude Code lê o arquivo `~/.claude/settings.json` a cada inicialização. Este projeto mantém arquivos de backup nomeados como `settings-NOME.json` e copia o escolhido como `settings.json` na hora de alternar.

```
~/.claude/
├── settings.json              ← ativo no momento
├── settings-minimax.json      ← backup MiniMax
├── settings-openrouter.json   ← backup OpenRouter
├── settings-glm.json          ← backup GLM
└── commands/
    └── switch-provider.md     ← slash command
```

---

## Contribuindo

Pull requests são bem-vindos! Sugestões de novos providers pré-configurados, melhorias nos scripts ou suporte a novas plataformas são especialmente apreciadas.

---

## Licença

MIT
