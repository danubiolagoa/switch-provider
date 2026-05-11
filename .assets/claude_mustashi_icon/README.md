# Claude Mustashi Icon Pack

Inventario inicial dos icones do Switch Provider.

## Arquivos disponiveis

| Arquivo | Uso previsto |
| --- | --- |
| `icon.png` | PNG principal, 1024x1024 |
| `icon_1024x1024.png` | PNG base em alta resolucao |
| `icon_512x512.png` | PNG para app stores, Linux e previews |
| `icon_256x256.png` | PNG para Windows/Linux |
| `icon_128x128.png` | PNG para atalhos e previews |
| `icon_64x64.png` | PNG para UI e atalhos menores |
| `icon_32x32.png` | PNG para toolbar/listas |
| `icon_16x16.png` | PNG para favicon/pequenos contextos |
| `icon.ico` | Icone Windows |
| `icon.icns` | Icone macOS futuro |

## Validacao feita

- PNGs conferidos com dimensoes esperadas: 16, 32, 64, 128, 256, 512 e 1024 px.
- Arquivos de plataforma presentes: `.ico` para Windows e `.icns` para macOS.

## Proximo uso

- Integrar `icon.ico` ao build Windows.
- Usar `icon.png` ou `icon_1024x1024.png` como fonte visual principal em docs/releases.
- Manter `icon.icns` reservado para empacotamento macOS posterior.
