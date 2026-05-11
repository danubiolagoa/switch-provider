# Changelog

## 1.0.3

- Migra o projeto para um aplicativo desktop Rust/Slint.
- Integra icone proprio ao executavel Windows e a janela Slint.
- Corrige sincronizacao entre provider ativo, backup `settings-NOME.json` e modelo OpenRouter.
- Adiciona carregamento e filtro de modelos OpenRouter na interface.
- Adiciona suporte inicial a OpenCode Zen e OpenCode Go como providers separados.
- Valida OpenCode Zen em uso real no Claude Code.
- Corrige IDs de modelo OpenCode para usar nomes crus do catalogo, como `kimi-k2.5`, sem prefixos invalidos.
- Remove `deepseek-v4-flash-free` da lista OpenCode Zen por incompatibilidade com tools/function calling do Claude Code.
- Oculta a API key no cadastro apos carregar modelos.
- Corrige tag `ATIVO` e "Ver configs" para comparar `settings.json` por conteudo estrutural, nao texto bruto.
- Recarrega o catalogo de modelos sempre que o usuario clica em "Mudar modelo".
- Ajusta renderer/tamanho minimo da janela para reduzir falhas ao mover entre monitores.
- Melhora "Ver configs" com conteudo real de `settings.json` e mascaramento de segredos.
- Remove NVIDIA do cadastro de providers.
- Remove scripts Bash/Batch, slash command legado, TUI Rust orfa e clientes API nao usados.
