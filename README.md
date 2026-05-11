# Switch Provider

Aplicativo desktop em Rust/Slint para gerenciar providers de LLM usados pelo Claude Code.

O Claude Code lê um único arquivo ativo em `~/.claude/settings.json`. O Switch Provider mantém backups como `settings-minimax.json`, `settings-openrouter.json` e outros `settings-NOME.json`, permitindo alternar o provider ativo sem reconfigurar tudo manualmente.

## Recursos

- Interface desktop para adicionar, ativar, renomear e remover providers.
- Providers suportados: MiniMax, OpenRouter, OpenCode Zen, OpenCode Go, Anthropic, Z.AI/GLM, Google AI, OpenAI e Custom.
- Troca dinâmica de modelo para OpenRouter, OpenCode Zen e OpenCode Go, com carregamento atualizado pela API e filtro na interface.
- OpenCode Zen validado em uso real com Claude Code. O catalogo usa IDs crus, como `kimi-k2.5`, sem prefixos `opencode/`.
- OpenCode Go fica disponivel como provider separado e requer assinatura OpenCode Go ativa.
- Modelos OpenCode Zen incompatíveis com tools/function calling do Claude Code podem ser ocultados da lista, como `deepseek-v4-flash-free`.
- Visualização segura do `settings.json`, com tokens e API keys mascarados.
- API key fica oculta apos carregar modelos no cadastro do provider.
- Escrita com arquivo temporário e backup `.bak` para reduzir risco de corrupção.
- Janela configurada com renderer `software` por padrão e tamanho mínimo para reduzir falhas ao mover entre monitores/DPI.

## Como instalar

### Windows

Baixe o instalador `.exe` na pagina de Releases do GitHub e execute com duplo clique.

Via PowerShell:

```powershell
irm https://raw.githubusercontent.com/danubiolagoa/switch-provider/main/install/install.ps1 | iex
```

Depois que o pacote for aceito no Winget, a instalacao tambem podera ser:

```powershell
winget install DanubioLagoa.SwitchProvider
```

### Linux

Via curl:

```bash
curl -fsSL https://raw.githubusercontent.com/danubiolagoa/switch-provider/main/install/install.sh | bash
```

O script tenta instalar `.deb` em distros com `apt`; se nao houver `.deb`, baixa o `.AppImage` para `~/.local/bin/switch-provider`.

### macOS

Via curl:

```bash
curl -fsSL https://raw.githubusercontent.com/danubiolagoa/switch-provider/main/install/install.sh | bash
```

O script baixa o `.dmg` da ultima release, monta o volume e copia o `.app` para `/Applications`.

Se o download for divulgado no site de um parceiro, a pagina pode apontar para esses mesmos scripts ou para os assets da GitHub Release.

## Como rodar em desenvolvimento

```powershell
cd switch-provider
cargo run
```

Build de release:

```powershell
cd switch-provider
cargo build --release
```

Executável gerado:

```text
switch-provider/target/release/switch-provider.exe
```

Gerar instalador Windows local:

```powershell
cd switch-provider
npx --yes @crabnebula/packager --config Packager.toml --formats nsis
```

O instalador NSIS sera gerado em `dist/`. Consulte `.docs/instalador-windows.md` para o checklist de QA.

## Configuração

Os arquivos ficam em `~/.claude`:

```text
~/.claude/
├── settings.json
├── settings-minimax.json
├── settings-openrouter.json
└── settings-outro-provider.json
```

Ao ativar um provider, o app lê o backup correspondente e grava seu conteúdo em `settings.json`.

## Segurança

Não commite `settings.json`, `settings-*.json`, chaves de API, binários gerados ou arquivos dentro de `target/`. O `.gitignore` já cobre esses casos.

Os instaladores não incluem suas chaves locais nem arquivos `settings*.json`; cada usuário cadastra os próprios providers após instalar.

## Desenvolvimento

```powershell
cd switch-provider
cargo test
cargo build --release
```

Antes de publicar alterações, valide pelo menos:

- alternar MiniMax -> OpenRouter -> MiniMax;
- trocar o modelo OpenRouter/OpenCode Zen e confirmar que `settings.json` e `settings-NOME.json` foram atualizados;
- confirmar OpenCode Zen funcionando no Claude Code com modelo aceito pelo gateway;
- confirmar que `Mudar modelo` recarrega o catalogo atual e nao mostra modelos bloqueados como `deepseek-v4-flash-free`;
- abrir "Ver configs" e confirmar que a chave está mascarada;
- mover a janela entre dois monitores e confirmar que ela nao minimiza/some;
- adicionar provider e confirmar que NVIDIA não aparece na lista.
