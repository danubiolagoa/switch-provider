# Publicacao, downloads e Winget

## Fluxo recomendado de release

1. Atualizar `VERSION` e `switch-provider/Cargo.toml`.
2. Rodar `cargo test` e `cargo build --release`.
3. Criar tag, por exemplo `v1.0.4`.
4. Fazer push da tag para o GitHub.
5. O workflow `.github/workflows/release.yml` gera e anexa os artefatos na GitHub Release:
   - Windows: instalador NSIS `.exe`.
   - Linux: `.deb` e `.AppImage`.
   - macOS: `.app` e `.dmg`.

## Links diretos para site parceiro

O GitHub permite link estavel para asset da ultima release:

```text
https://github.com/danubiolagoa/switch-provider/releases/latest/download/NOME_DO_ARQUIVO
```

O site parceiro pode ter botoes comuns de download ou comandos:

```powershell
irm https://raw.githubusercontent.com/danubiolagoa/switch-provider/main/install/install.ps1 | iex
```

```bash
curl -fsSL https://raw.githubusercontent.com/danubiolagoa/switch-provider/main/install/install.sh | bash
```

Se preferir hospedar scripts no site parceiro, basta manter o conteudo de `install/install.ps1` e `install/install.sh` apontando para o repo GitHub.

## Winget

O Winget oficial nao e publicado dentro deste repositorio. Ele exige um manifest submetido ao repositorio comunitario `microsoft/winget-pkgs`.

Fluxo:

1. Publicar o instalador `.exe` em uma GitHub Release publica.
2. Calcular SHA256 do instalador:

```powershell
winget hash .\dist\switch-provider_1.0.4_x64-setup.exe
```

3. Criar manifest com `wingetcreate`:

```powershell
winget install wingetcreate
wingetcreate new https://github.com/danubiolagoa/switch-provider/releases/latest/download/switch-provider_1.0.4_x64-setup.exe
```

4. Usar os metadados:
   - PackageIdentifier: `DanubioLagoa.SwitchProvider`
   - PackageName: `Switch Provider`
   - Publisher: `Danubio Lagoa`
   - License: `MIT`
   - InstallerType: `nullsoft`

5. Submeter o manifest ao `microsoft/winget-pkgs`.

Depois de aceito:

```powershell
winget install DanubioLagoa.SwitchProvider
```

Eu consigo preparar os arquivos/instrucoes e, se houver GitHub CLI autenticado com permissao, abrir o PR. A aprovacao final depende do repositorio Winget da Microsoft.
