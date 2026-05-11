# Todo List - Proxima Sessao

Projeto: Switch Provider v1.0.3

## Concluido

- [x] Planejamento base criado em `.docs/proxima-sessao-planejamento.md`.
- [x] Pasta de icones criada em `.assets/claude_mustashi_icon`.
- [x] Icones PNG conferidos nos tamanhos 16, 32, 64, 128, 256, 512 e 1024 px.
- [x] Arquivos de plataforma presentes: `icon.ico` para Windows e `icon.icns` para macOS futuro.
- [x] Provider OpenCode Zen adicionado ao planejamento como tarefa futura de validacao/implementacao.
- [x] `icon.ico` copiado para `switch-provider/assets/icon.ico`.
- [x] `icon_256x256.png` copiado para `switch-provider/assets/icon_256x256.png`.
- [x] Icone integrado ao build Windows via `winresource`.
- [x] Icone integrado a janela Slint via `icon: @image-url(...)`.
- [x] Build local validado com `cargo build`.
- [x] Executavel release regenerado em `switch-provider/target/release/switch-provider.exe`.
- [x] Testes Rust validados com `cargo test`.
- [x] Icone associado extraido dos executaveis `target/debug/switch-provider.exe` e `target/release/switch-provider.exe`.
- [x] Provider OpenCode Zen adicionado ao fluxo de cadastro.
- [x] Provider OpenCode Go adicionado ao fluxo de cadastro.
- [x] OpenCode Zen configurado com endpoint base `https://opencode.ai/zen` e catalogo `https://opencode.ai/zen/v1/models`.
- [x] OpenCode Go configurado com endpoint base `https://opencode.ai/zen/go` e catalogo `https://opencode.ai/zen/go/v1/models`.
- [x] UI registra que OpenCode Go requer assinatura ativa.
- [x] UI registra que OpenCode Zen possui modelos gratuitos e modelos maiores por creditos da plataforma Zen.
- [x] Licenca MIT conferida e titular ajustado em `LICENSE`.
- [x] Release notes preparadas em `.docs/release-notes-v1.0.3.md`.
- [x] Tag `v1.0.3` preparada como comando pos-commit nas release notes.
- [x] API key do fluxo de cadastro fica oculta apos carregar modelos.
- [x] Secret scan local executado sem encontrar chaves reais nos arquivos versionaveis.
- [x] Executavel release regenerado apos ajustes de OpenCode/API key.
- [x] Corrigido model id OpenCode: catalogos Zen/Go usam ids crus como `kimi-k2.5`, sem prefixos `opencode/` ou `opencode-go/`.
- [x] Ativacao de providers OpenCode antigos remove prefixos invalidos automaticamente antes de escrever `settings.json`.
- [x] `deepseek-v4-flash-free` removido da lista selecionavel do OpenCode Zen por falhar no payload de tools/function calling do Claude Code.
- [x] Ao clicar em `Mudar modelo`, o app recarrega o catalogo atual do provider ativo automaticamente.
- [x] Tag `ATIVO` corrigida para comparar o conteudo estrutural do `settings.json`, nao texto bruto.
- [x] `Ver configs` corrigido para identificar o provider salvo mesmo quando o JSON ativo foi reformatado.
- [x] Renderer Slint padronizado para `software` quando `SLINT_BACKEND` nao estiver definido, reduzindo falhas ao mover entre monitores.
- [x] Tamanho minimo da janela definido para evitar colapso visual ao alternar telas/DPI.
- [x] `cargo test` validado apos a correcao de dois monitores: 12 testes passaram.
- [x] `cargo build` validado apos a correcao de dois monitores.
- [x] `cargo build --release` concluiu e regenerou `switch-provider/target/release/switch-provider.exe` em 2026-05-11.
- [x] OpenCode Zen validado em uso real no Claude Code.
- [x] Documentacao atualizada para refletir OpenCode Zen validado e OpenCode Go pendente de assinatura.

## Em andamento

Nenhuma tarefa em andamento neste bloco.

## Dependem do instalador Windows

- [x] Criar instalador Windows com `switch-provider/Packager.toml` e CrabNebula Packager/NSIS.
- [x] Gerar `dist/switch-provider_1.0.3_x64-setup.exe`.
- [x] Testar instalacao e desinstalacao silenciosa em `C:\tmp\switch-provider-install-test`.
- [ ] Validar o icone em atalho instalado pelo Start Menu em instalacao interativa.
- [ ] Testar execucao visual do app instalado em ambiente limpo.

## Bloqueado por credenciais

- [ ] Validar com API key real e assinatura ativa se OpenCode Go ativa e executa modelos no Claude Code.

## Falta antes de publicar

- [ ] Repetir varredura de secrets imediatamente antes de publicar/taguear.
- [x] Manter macOS e Linux como backlog posterior.

## Reteste manual recomendado

- [ ] Abrir `switch-provider/target/release/switch-provider.exe` e mover a janela entre os dois monitores para confirmar que nao minimiza/some.
- [ ] Confirmar que OpenCode Zen continua ativo e funcional depois da correcao visual.
- [ ] Confirmar que `Mudar modelo` recarrega o catalogo automaticamente e nao mostra `deepseek-v4-flash-free`.
- [ ] Confirmar que `Ver configs` mostra o `settings.json` ativo com segredos mascarados.

## Proximo passo recomendado

Na proxima sessao, fazer QA interativo do instalador Windows gerado, mantendo o reteste manual acima antes de publicar/taguear.
