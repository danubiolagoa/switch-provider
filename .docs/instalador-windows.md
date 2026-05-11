# Instalador Windows

Status: configurado e gerado localmente com CrabNebula Packager via npm.

## Ferramenta escolhida

O projeto usa `switch-provider/Packager.toml` com formato inicial `nsis`, gerando um instalador `.exe` para Windows.

Motivos:

- Mantem o fluxo simples para a release Windows.
- Instala por usuario atual, sem exigir administrador por padrao.
- Reaproveita a mesma ferramenta futuramente para macOS e Linux.
- Mantem `settings.json` e backups em `~/.claude`, fora do pacote instalado.

## Comandos

Verificar a ferramenta via npm:

```powershell
npx --yes @crabnebula/packager --version
```

Gerar o instalador:

```powershell
cd switch-provider
npx --yes @crabnebula/packager --config Packager.toml --formats nsis
```

Artefatos esperados:

```text
dist/switch-provider_1.0.3_x64-setup.exe
```

Observacao: `cargo install cargo-packager --locked` tambem e uma opcao valida, mas nesta maquina falhou porque o workload C++/MSVC do Visual Studio esta incompleto e nao possui `vcruntime.h`. O caminho `npx --yes @crabnebula/packager` foi validado e gerou o instalador.

## Checklist de QA Windows

- Rodar `cargo test`.
- Rodar `cargo build --release`.
- Gerar o instalador NSIS com `npx --yes @crabnebula/packager --config Packager.toml --formats nsis`.
- Confirmar que o pacote nao inclui `settings.json`, `settings-*.json` ou API keys.
- Instalar o app pelo `.exe` gerado em `dist/`.
- Abrir pelo Start Menu e confirmar icone/nome `Switch Provider`.
- Confirmar que o app le e grava em `~/.claude/settings.json`.
- Validar MiniMax -> OpenRouter -> MiniMax.
- Validar troca de modelo OpenRouter/OpenCode atualizando `settings.json` e o backup ativo.
- Abrir "Ver configs" e confirmar secrets mascarados.
- Desinstalar e confirmar que app/atalhos saem sem apagar as configuracoes do usuario em `~/.claude`.

## macOS e Linux

O codigo atual e majoritariamente portavel: a logica principal usa Rust/Slint e caminho `~/.claude`. Os trechos nativos de Windows estao protegidos com `#[cfg(windows)]`.

Mesmo assim, macOS e Linux precisam de ajustes e validacoes de empacotamento antes de release publica:

- macOS: gerar `.app`/`.dmg`, usar `icon.icns`, testar em macOS real e decidir assinatura/notarizacao.
- Linux: gerar AppImage e/ou `.deb`, validar desktop entry/icone, testar em distro com Wayland/X11, glibc e d-bus.

Essas plataformas permanecem fora do criterio de aceite da release Windows.
