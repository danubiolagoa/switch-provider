---
name: Gerar e validar instaladores Linux
about: Ajude a gerar ou testar pacotes Linux do Switch Provider
title: "Gerar e validar instaladores Linux"
labels: packaging, help wanted, linux
assignees: ""
---

## Objetivo

Gerar e validar os instaladores Linux do Switch Provider a partir do workflow de release e/ou de builds locais em uma distro real.

## Tarefas

- [ ] Gerar pacote `.deb`.
- [ ] Gerar pacote `.AppImage`.
- [ ] Testar em uma distro Linux real.
- [ ] Confirmar que a interface Slint abre corretamente.
- [ ] Confirmar leitura/gravação em `~/.claude/settings.json`.
- [ ] Confirmar que o pacote não inclui `settings.json`, `settings-*.json` nem API keys.

## Critérios de aceite

- O usuário final consegue instalar e abrir o app no Linux.
- O app preserva as configurações locais do usuário em `~/.claude`.
- Nenhum segredo ou arquivo local de teste é empacotado.
- O usuário configura as próprias chaves após instalar.

## Observações

- Windows já possui instalador NSIS `.exe` gerado e validado localmente.
- Linux deve ser validado separadamente antes de entrar como download oficial.
