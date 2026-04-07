# Switch Provider

Gerencie e alterne entre providers de LLM configurados para o Claude Code.

## Otimização de performance

**Execute operações de arquivo em batches — MÁXIMO 1 chamada bash por iteração.**

Cada `bash -c` novo adiciona ~100-300ms de overhead. O menu precisa ser rápido.

## Comportamento obrigatório

**Você DEVE executar em loop contínuo.** Após qualquer ação (alternar, adicionar, remover, ver), volte automaticamente ao menu principal e apresente as opções novamente. Só encerre quando o usuário explicitamente escolher "Sair" ou digitar `0` ou `sair`.

Nunca encerre o comando após uma única ação.

---

## Fluxo principal (loop)

### Passo 1 — Colete o estado atual (UMA única chamada bash)

Execute **TODAS** as operações de arquivo em UM script bash só:

```bash
bash -c '
PROVIDERS=$(ls ~/.claude/settings-*.json 2>/dev/null | sed "s|.*/settings-|~s-|.json||")
CURRENT=$(grep -o "api\.[^.]\+" ~/.claude/settings.json 2>/dev/null | head -1 | sed "s|api\.||;s|/.*||")
[ -z "$CURRENT" ] && grep -q "ANTHROPIC_API_KEY" ~/.claude/settings.json && CURRENT="anthropic"
[ -z "$CURRENT" ] && CURRENT="desconhecido"
echo "PROVIDERS:$PROVIDERS"
echo "CURRENT:$CURRENT"
'
```

**Por que uma única chamada:**
- Cada processo bash tem ~100-300ms de overhead
- Separar em 2-3 chamadas = 300-900ms perdido
- Uma única chamada = overhead mínimo

**Interpretação da saída:**
- `PROVIDERS:minimax~s~openrouter~s~glm` → lista separada por `~s~`
- `CURRENT:minimax` ou `CURRENT:desconhecido`

### Passo 2 — Exiba o menu

Monte o menu dinamicamente com os providers encontrados numerados. Exemplo:

```
==========================================
  Claude Code - Provider Manager
==========================================
  Ativo agora: minimax
------------------------------------------
  Providers disponíveis:
  [1] minimax
  [2] openrouter
------------------------------------------
  [a] Adicionar novo provider
  [r] Remover provider
  [m] Trocar modelo (OpenRouter)
  [v] Ver settings.json completo
  [0] Sair
==========================================
```

### Passo 3 — Processe a escolha e VOLTE AO MENU

Para cada opção, execute a ação correspondente abaixo, confirme o resultado ao usuário, e **imediatamente** apresente o menu novamente sem esperar novo comando.

---

## Ações

### Alternar provider (número da lista)

**ANTES de copiar o novo provider**, faça backup automático — tudo em UMA chamada:

```bash
bash -c '
BACKUP_NAME=$(ls ~/.claude/settings-*.json 2>/dev/null | while read f; do
  diff -q "$f" ~/.claude/settings.json > /dev/null 2>&1 && basename "$f" .json | sed "s/settings-//"
done | head -1)

if [ -z "$BACKUP_NAME" ]; then
  BACKUP_NAME=$(grep -o "api\.[^.]\+" ~/.claude/settings.json 2>/dev/null | head -1 | sed "s|api\.||;s|/.*||")
  [ -z "$BACKUP_NAME" ] && BACKUP_NAME="backup"
  cp ~/.claude/settings.json ~/.claude/settings-${BACKUP_NAME}.json
  echo "Backup salvo: settings-${BACKUP_NAME}.json"
fi

cp ~/.claude/settings-NOME.json ~/.claude/settings.json
echo "Provider ativado: NOME"
'
```

**APÓS ativar**, mostre SEMPRE esta mensagem:

```
╔══════════════════════════════════════════════════╗
║  [OK] Provider NOME ativado!
╠══════════════════════════════════════════════════╣
║  IMPORTANTE: Reinicie o Claude Code para         ║
║  aplicar a mudanca!                              ║
║                                                  ║
║  Feche e abra novamente o Claude Code.          ║
╚══════════════════════════════════════════════════╝
```

Mostre ao usuário qual backup foi criado (se houve) e qual provider está ativo agora. Depois, **volte ao menu**.

### [a] Adicionar novo provider

**Fluxo completo:**

1. **Escolher endpoint** — ofereça as opções:
   - `[1]` MiniMax → `https://api.minimax.io/anthropic`
   - `[2]` OpenRouter → `https://openrouter.ai/api`
   - `[3]` Anthropic nativo → *(sem BASE_URL, usa ANTHROPIC_API_KEY)*
   - `[4]` Z.AI / GLM → `https://api.z.ai/api/anthropic`
   - `[5]` Google AI Studio (Gemini) → `https://generativelanguage.googleapis.com`
   - `[6]` OpenAI (GPT) → `https://api.openai.com/v1`
   - `[7]` Outro → digitar manualmente

2. **Nome** do provider (ex: `openrouter`, `glm`, `minimax`)

3. **API Key**

4. **Seleção de modelos por slot — Método organizado:**

   Ofereça dois formatos para preenchimento:

   **Opção A: Colar lista formatada**
   ```
   principal:qwen/qwen2.5-7b-instruct:free
   rapido:google/gemini-2.0-flash-exp:free
   sonnet:meta-llama/llama-3.2-3b-instruct:free
   opus:qwen/qwen2.5-7b-instruct:free
   haiku:google/gemini-2.0-flash-exp:free
   ```

   **Opção B: Preencher um por um** (ENTER para pular)
   ```
   Slot: MODELO PRINCIPAL
   > digite ou cole ID do modelo
   ```

   Para OpenRouter, ofereça buscar lista atualizada:
   ```bash
   curl -s "https://openrouter.ai/api/v1/models" \
     -H "Authorization: Bearer $API_KEY"
   ```

5. **Slots disponíveis:**

   | Slot | Variável | Descrição |
   |---|---|---|
   | Principal | `ANTHROPIC_MODEL` | Modelo padrão geral |
   | Rápido | `ANTHROPIC_SMALL_FAST_MODEL` | Tarefas simples (equivale ao Haiku) |
   | Sonnet | `ANTHROPIC_DEFAULT_SONNET_MODEL` | Tarefas intermediárias |
   | Opus | `ANTHROPIC_DEFAULT_OPUS_MODEL` | Tarefas complexas |
   | Haiku | `ANTHROPIC_DEFAULT_HAIKU_MODEL` | Tarefas leves |

6. **Confirmação** — Mostre todos os modelos selecionados antes de salvar:

   ```
   ==========================================
     Confirmar Configuracao
   ==========================================
     Provider: openrouter
     Endpoint: https://openrouter.ai/api

   Modelos selecionados:
     Principal:   qwen/qwen2.5-7b-instruct:free
     Rapido:      google/gemini-2.0-flash-exp:free
     Sonnet:      qwen/qwen2.5-7b-instruct:free
     Opus:        meta-llama/llama-3.2-3b-instruct:free
     Haiku:       google/gemini-2.0-flash-exp:free

   ==========================================
     [ENTER] Confirmar e salvar
     [n] Cancelar
   ```

7. **Gerar arquivo** — Após confirmação, salve `~/.claude/settings-NOME.json`

8. **Ativação** — Pergunte se deseja ativar imediatamente

Depois, **volte ao menu**.

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

Exiba o conteúdo, mas **substitua o valor completo** de `ANTHROPIC_AUTH_TOKEN` e `ANTHROPIC_API_KEY` por apenas os **4 primeiros caracteres** seguidos de `****************************`:

```
"ANTHROPIC_AUTH_TOKEN": "sk-a****************************"
"ANTHROPIC_API_KEY":    "sk-a****************************"
```

Nunca exiba mais do que 4 caracteres de qualquer API key, em nenhuma situação. Após exibir, **volte ao menu**.

### [m] Trocar modelo do OpenRouter

**ATENÇÃO: Esta funcionalidade substitui o `/model` do Claude Code para modelos externos.**

Quando o provider ativo é OpenRouter, oferece opção de trocar o modelo principal.

**Fluxo:**

1. **Buscar modelos** — Chama API do OpenRouter:
   ```bash
   curl -s "https://openrouter.ai/api/v1/models" \
     -H "Authorization: Bearer $ANTHROPIC_AUTH_TOKEN"
   ```

2. **Exibir menu numerado** — Lista os modelos disponíveis:
   ```
   ==========================================
     Selecionar Modelo - OpenRouter
   ==========================================
     Providers: minimax | openrouter | glm
     Ativo agora: openrouter
   ------------------------------------------
     Modelos disponíveis:
     [1] moonshotai/kimi-k2.5 ........ $0.00/M
     [2] z-ai/glm-5-turbo ........... $0.00/M
     [3] openrouter/auto .............. $0.00/M
     ...
   ------------------------------------------
     [p] Próxima página | [a] Anterior página
     [0] Cancelar
   ==========================================
   ```

3. **Processar seleção** — Atualiza `ANTHROPIC_MODEL` no settings.json:
   ```bash
   # Atualiza apenas o modelo principal
   jq ".env.ANTHROPIC_MODEL = \"$NOVO_MODELO\"" ~/.claude/settings.json > /tmp/settings_tmp.json
   mv /tmp/settings_tmp.json ~/.claude/settings.json
   ```

4. **Confirmar** — Mostra o modelo ativado e volta ao menu.

**Nota:** Modelos `:free` são ilimitados mas podem ter rate limits. Modelos pagos usam créditos da sua conta OpenRouter.

---

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
- **Sempre fazer backup automático** do settings.json atual antes de trocar
- **Sempre avisar para reiniciar o Claude Code** após ativar provider
- Nunca remova o `settings.json` principal, apenas os `settings-*.json`
- Se não houver nenhum `settings-*.json`, informe no menu e sugira usar `[a]` para adicionar
- Ao exibir o provider ativo, compare o `settings.json` com os backups para identificá-lo pelo nome
- Para OpenRouter, sempre ofereça buscar a lista atualizada de modelos antes de perguntar os slots
- Ofereça sempre a opção de colar lista formatada de modelos (formato: `tipo:modelo`)
- **A opção `[m]` só aparece quando o provider ativo é OpenRouter** — para outros providers, esconda ou desabilite

---

## Aviso para novos usuários

> ⚠️ Este slash command só funciona depois que o Claude Code já está rodando com um provider válido.
> Para o primeiro setup, use `claude-switch.bat` (Windows) ou `claude-switch.sh` (Linux/Mac).

---

## Sobre

Faz parte do **switch-provider** — projeto open source para gerenciar múltiplos providers de LLM no Claude Code.
