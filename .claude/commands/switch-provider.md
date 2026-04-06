# Switch Provider

Gerencie e alterne entre providers de LLM configurados para o Claude Code.

## Comportamento obrigatório

**Você DEVE executar em loop contínuo.** Após qualquer ação (alternar, adicionar, remover, ver), volte automaticamente ao menu principal e apresente as opções novamente. Só encerre quando o usuário explicitamente escolher "Sair" ou digitar `0` ou `sair`.

Nunca encerre o comando após uma única ação.

---

## Fluxo principal (loop)

### Passo 1 — Colete o estado atual

Execute sempre antes de exibir o menu:

```bash
# Providers disponíveis
ls ~/.claude/settings-*.json 2>/dev/null | sed 's|.*settings-||;s|\.json||'
```

```bash
# Provider ativo
cat ~/.claude/settings.json 2>/dev/null | grep -E "ANTHROPIC_BASE_URL|ANTHROPIC_API_KEY|ANTHROPIC_MODEL" | head -3
```

### Passo 2 — Exiba o menu

Monte o menu dinamicamente com os providers encontrados numerados. Exemplo de como deve aparecer:

```
╔══════════════════════════════════════╗
║     Claude Code - Provider Manager  ║
╠══════════════════════════════════════╣
║  Ativo agora: MiniMax               ║
╠══════════════════════════════════════╣
║  Providers disponíveis:             ║
║  [1] minimax                        ║
║  [2] openrouter                     ║
╠══════════════════════════════════════╣
║  [a] Adicionar novo provider        ║
║  [r] Remover provider               ║
║  [v] Ver settings.json completo     ║
║  [0] Sair                           ║
╚══════════════════════════════════════╝
```

### Passo 3 — Processe a escolha e VOLTE AO MENU

Para cada opção, execute a ação correspondente abaixo, confirme o resultado ao usuário, e **imediatamente** apresente o menu novamente sem esperar novo comando.

---

## Ações

### Alternar provider (número da lista)

```bash
cp ~/.claude/settings-NOME_ESCOLHIDO.json ~/.claude/settings.json
echo "✓ Provider ativado:" && grep -E "ANTHROPIC_BASE_URL|ANTHROPIC_MODEL|ANTHROPIC_API_KEY" ~/.claude/settings.json
```

Após confirmar, volte ao menu.

### [a] Adicionar novo provider

Pergunte ao usuário em sequência:

1. **Endpoint** — ofereça as opções:
   - `[1]` MiniMax → `https://api.minimax.io/anthropic`
   - `[2]` OpenRouter → `https://openrouter.ai/api/v1`
   - `[3]` Anthropic nativo → *(sem BASE_URL, usa ANTHROPIC_API_KEY)*
   - `[4]` Z.AI / GLM → `https://api.z.ai/api/anthropic`
   - `[5]` Outro → digitar manualmente

2. **Nome** do provider (ex: `openrouter`, `glm`, `meu-custom`)

3. **API Key**

4. **Modelo principal** — sugira o padrão do endpoint escolhido:
   - MiniMax → `MiniMax-M2.7`
   - OpenRouter → `qwen/qwen3-235b-a22b:free`
   - GLM → `GLM-4.7`
   - Anthropic → `claude-sonnet-4-20250514`

Gere o arquivo:

**Para providers com BASE_URL:**
```bash
cat > ~/.claude/settings-NOME.json << 'EOF'
{
  "env": {
    "ANTHROPIC_BASE_URL": "ENDPOINT",
    "ANTHROPIC_AUTH_TOKEN": "API_KEY",
    "API_TIMEOUT_MS": "3000000",
    "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC": "1",
    "ANTHROPIC_MODEL": "MODELO",
    "ANTHROPIC_SMALL_FAST_MODEL": "MODELO",
    "ANTHROPIC_DEFAULT_SONNET_MODEL": "MODELO",
    "ANTHROPIC_DEFAULT_HAIKU_MODEL": "MODELO",
    "ANTHROPIC_DEFAULT_OPUS_MODEL": "MODELO"
  },
  "autoUpdatesChannel": "latest"
}
EOF
```

**Para Anthropic nativo:**
```bash
cat > ~/.claude/settings-NOME.json << 'EOF'
{
  "env": {
    "ANTHROPIC_API_KEY": "API_KEY",
    "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC": "1"
  },
  "autoUpdatesChannel": "latest"
}
EOF
```

Pergunte se deseja ativar imediatamente. Se sim, copie para `settings.json`. Depois, **volte ao menu**.

### [r] Remover provider

Liste os `settings-*.json` disponíveis numerados. Peça qual remover. Confirme antes de apagar:

```bash
rm ~/.claude/settings-NOME.json
```

Nunca remova o `settings.json` principal. Após remover, **volte ao menu**.

### [v] Ver settings.json completo

```bash
cat ~/.claude/settings.json
```

Exiba o conteúdo, mas **substitua o valor completo** de `ANTHROPIC_AUTH_TOKEN` e `ANTHROPIC_API_KEY` por apenas os **4 primeiros caracteres** seguidos de `****************************` — por exemplo:

```
"ANTHROPIC_AUTH_TOKEN": "sk-a****************************"
"ANTHROPIC_API_KEY":    "sk-a****************************"
```

Nunca exiba mais do que 4 caracteres de qualquer API key, em nenhuma situação — inclusive ao confirmar ativação de provider ou ao adicionar um novo. Após exibir, **volte ao menu**.

### [0] Sair

Encerre o comando e despeça-se.

---

## Regras de segurança — API Keys

- **Sempre** truncar após os 4 primeiros caracteres
- Usar `****************************` como sufixo fixo
- Aplicar em **todas** as situações: menu, confirmações, adição, listagem
- Nunca exibir a key completa, independente do contexto

---

## Regras gerais

- **Nunca encerre após uma ação** — sempre volte ao menu
- Nunca remova o `settings.json` principal, apenas os `settings-*.json`
- Se não houver nenhum `settings-*.json`, informe no menu e sugira usar `[a]` para adicionar

---

## Aviso para novos usuários

> ⚠️ Este slash command só funciona depois que o Claude Code já está rodando com um provider válido.
> Para o primeiro setup, use `claude-switch.bat` (Windows) ou `claude-switch.sh` (Linux/Mac).

---

## Sobre

Faz parte do **claude-provider-manager** — projeto open source para gerenciar múltiplos providers de LLM no Claude Code.
