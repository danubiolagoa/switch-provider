# Seguranca dos instaladores

## O que entra no pacote

Os instaladores devem incluir apenas o necessario para executar o Switch Provider:

- executavel do app;
- icones e metadados do aplicativo;
- arquivos auxiliares exigidos pelo empacotador;
- desinstalador, quando o formato oferecer.

## O que nao entra no pacote

Nunca incluir:

- `~/.claude/settings.json`;
- `~/.claude/settings-*.json`;
- API keys;
- arquivos `.tmp` ou `.bak`;
- `switch-provider/target/`;
- `dist/`;
- arquivos locais de teste.

## Fluxo do usuario final

1. O usuario baixa o instalador da GitHub Release ou usa `irm`/`curl`.
2. O instalador instala somente o app.
3. Ao abrir o Switch Provider, o usuario cadastra as proprias chaves/providers.
4. O app grava as configuracoes no `~/.claude` do proprio usuario.

## Verificacao antes de publicar

Antes de anexar artefatos em uma release publica:

```powershell
rg -l --hidden --glob '!switch-provider/target/**' --glob '!dist/**' --glob '!.git/**' "sk-[A-Za-z0-9_-]{20,}|OPENROUTER_API_KEY|ANTHROPIC_API_KEY|api[_-]?key"
```

Tambem conferir manualmente:

- conteudo de `dist/`;
- lista de arquivos empacotados pelo instalador;
- README e docs sem chaves reais;
- `.gitignore` cobrindo `settings*.json`, `target/`, `dist/`, `.tmp`, `.bak`, `.exe` e `.pdb`.
