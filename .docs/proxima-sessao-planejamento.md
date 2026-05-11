# Planejamento para a proxima sessao

Data: 2026-05-08
Projeto: Switch Provider v1.0.3

## Objetivo

Finalizar os itens de empacotamento, publicacao e polimento antes de preparar o app para usuarios finais.

## Pendencias priorizadas

### 1. Criar icone da aplicacao

- Status: parcialmente concluido.
- Criar um icone proprio para o Switch Provider. Concluido em `.assets/claude_mustashi_icon`.
- Gerar formatos adequados para Windows, especialmente `.ico`. Concluido: `icon.ico` presente.
- Gerar formatos auxiliares para plataformas futuras. Concluido: PNGs 16, 32, 64, 128, 256, 512 e 1024 px, alem de `icon.icns`.
- Integrar o icone ao build Rust/Slint e ao executavel final. Concluido em `switch-provider/assets`, `switch-provider/build.rs` e `switch-provider/ui/appwindow.slint`.
- Validar se aparece corretamente na janela e no executavel final. Concluido com `cargo build`, `cargo build --release` e extracao de icone associado dos executaveis debug/release.
- Validar atalho instalado depois que o instalador Windows for criado. Pendente ate existir instalador/atalho.

### 2. Licenca MIT e tags no GitHub

- Confirmar se o `LICENSE` atual esta correto para MIT.
- Atualizar metadados do projeto, se necessario.
- Criar tag de versao no GitHub para a release atual.
- Preparar release notes curtas com foco na versao Rust/Slint.

### 3. Ocultar API key do OpenRouter no fluxo de cadastro

- No cadastro de OpenRouter, depois que a chave for inserida e o usuario abrir a lista de modelos, a chave nao deve continuar visivel.
- Trocar o campo visivel por estado mascarado ou por etapa separada.
- Garantir que a key continue em memoria apenas para carregar modelos e salvar provider.
- Validar que nenhuma mensagem, status ou tela de confirmacao exponha a chave.

### 4. Criar instalador para Windows

- Status: configurado e gerado localmente em 2026-05-11.
- Ferramenta definida: CrabNebula Packager com formato NSIS.
- Configuracao criada em `switch-provider/Packager.toml`.
- Instalador gerado em `dist/switch-provider_1.0.3_x64-setup.exe`.
- Instalacao e desinstalacao silenciosa validadas em `C:\tmp\switch-provider-install-test`.
- Pendente: validar instalacao interativa, icone/atalho no Start Menu e execucao visual do app instalado.

### 5. Deixar MacOS e Linux como pendentes

- Registrar oficialmente que MacOS e Linux ficam para etapa posterior.
- Nao bloquear a release Windows por falta dessas versoes.
- Criar backlog separado para empacotamento futuro:
  - MacOS: app bundle, assinatura/notarizacao se necessario.
  - Linux: AppImage, deb/rpm ou pacote equivalente.

### 6. Avaliar e adicionar Provider OpenCode Zen e OpenCode Go

- Status: OpenCode Zen implementado e validado em uso real; OpenCode Go implementado, pendente de validacao com assinatura ativa.
- Adicionar suporte ao provider OpenCode Zen.
- Adicionar suporte ao provider OpenCode Go.
- Validar a integracao contra a documentacao oficial atual:
  - Zen usa a familia `https://opencode.ai/zen`, com lista de modelos em `https://opencode.ai/zen/v1/models`.
  - Os endpoints variam por familia de modelo, por exemplo `https://opencode.ai/zen/v1/responses`, `https://opencode.ai/zen/v1/messages` e `https://opencode.ai/zen/v1/chat/completions`.
  - OpenCode Go usa endpoints separados em `https://opencode.ai/zen/go/v1/...`, incluindo `https://opencode.ai/zen/go/v1/models`.
- Tratar a configuracao como dois endpoints separados:
  - OpenCode Zen: endpoint base `https://opencode.ai/zen`.
  - OpenCode Go: endpoint base `https://opencode.ai/zen/go`.
- Implementado na UI como dois providers separados para evitar confusao de endpoint e formato de model id.
- OpenCode Zen: frisar modelos gratuitos e modelos maiores pagos com creditos de API da plataforma Zen.
- OpenCode Zen: ocultar modelos gratuitos que falhem com tools/function calling do Claude Code, como `deepseek-v4-flash-free`.
- OpenCode Zen: usar IDs crus do catalogo, como `kimi-k2.5`, sem prefixos `opencode/`.
- OpenCode Go: frisar que requer assinatura OpenCode Go ativa.
- Validar autenticacao com API key, carregamento de modelos, selecao de modelo e gravacao correta em `settings.json`. Concluido para OpenCode Zen.
- Confirmar com API key real se os modelos do OpenCode Go podem ser usados fora da TUI no Claude Code e se a conta possui assinatura/permissao ativa.
- Manter a mesma regra de seguranca do OpenRouter: nunca expor API key em logs, status, telas ou docs.

## Criterios de aceite da proxima sessao

- App Windows com icone proprio.
- Instalador Windows gerado e testado localmente em fluxo silencioso.
- Chave OpenRouter nao fica visivel apos iniciar carregamento/escolha de modelos.
- Provider OpenCode Zen validado com endpoint real, listagem de modelos, gravacao e uso no Claude Code.
- Provider OpenCode Go implementado com endpoint real e pendente de validacao com assinatura ativa.
- Licenca MIT e tag/release GitHub preparados.
- Pendencias MacOS/Linux documentadas sem misturar com a release Windows.

## Observacoes

- Preservar arquivos globais em `C:\Users\danub\.claude` e nunca expor API keys.
- Antes de qualquer publicacao, fazer nova varredura de secrets e conferir `git status`.
- `switch-provider/target/` deve permanecer fora do Git.
- Todo list operacional criada em `.docs/todo-proxima-sessao.md`.
- Proxima etapa principal: planejar o instalador Windows.
