# Release Notes - v1.0.3

## Destaques

- Migra o Switch Provider para aplicativo desktop Rust/Slint.
- Adiciona gerenciamento visual de providers para Claude Code.
- Integra icone proprio ao executavel Windows e a janela do app.
- Mantem OpenRouter com listagem, filtro e selecao de modelos.
- Adiciona providers OpenCode Zen e OpenCode Go como endpoints separados.
- OpenCode Zen usa `https://opencode.ai/zen`, foi validado em uso real no Claude Code e informa modelos gratuitos, alem de modelos maiores por creditos da plataforma Zen.
- OpenCode Go usa `https://opencode.ai/zen/go` e informa que requer assinatura OpenCode Go ativa.
- Corrige IDs OpenCode para usar nomes crus do catalogo, como `kimi-k2.5`, sem prefixos invalidos.
- Oculta `deepseek-v4-flash-free` da lista Zen por falhar com tools/function calling no Claude Code.
- Mascara API keys em visualizacao de configs e oculta a API key apos carregar modelos no cadastro.
- Corrige deteccao de provider ativo e leitura de configs usando comparacao estrutural do `settings.json`.
- Recarrega o catalogo de modelos ao clicar em `Mudar modelo`.
- Usa renderer Slint `software` por padrao e tamanho minimo de janela para reduzir falhas em setups com dois monitores/DPI diferentes.

## Validacoes locais

- `cargo build`
- `cargo build --release`
- `cargo test`
- Icone associado validado nos executaveis debug/release.
- OpenCode Zen validado manualmente no Claude Code.
- Reteste manual pendente/recomendado: mover janela entre dois monitores com o release atualizado.

## Tag sugerida

Criar a tag somente depois do commit final da release:

```powershell
git tag v1.0.3
git push origin v1.0.3
```

## Pendencias fora desta release

- Instalador Windows.
- Validacao do icone em atalho instalado.
- Validacao OpenCode Go com assinatura ativa.
- Empacotamento macOS/Linux.
