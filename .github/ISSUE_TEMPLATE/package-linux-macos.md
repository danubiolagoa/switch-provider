---
name: Gerar e validar instaladores Linux/macOS
about: Ajude a gerar ou testar pacotes Linux e macOS do Switch Provider
title: "Gerar e validar instaladores Linux/macOS"
labels: packaging, help wanted, linux, macos
assignees: ""
---

## Objetivo

Gerar e validar os instaladores Linux e macOS do Switch Provider a partir do workflow de release e/ou de builds locais nas plataformas reais.

## Linux

- [ ] Gerar pacote `.deb`.
- [ ] Gerar pacote `.AppImage`.
- [ ] Testar em uma distro Linux real.
- [ ] Confirmar que a interface Slint abre corretamente.
- [ ] Confirmar leitura/gravação em `~/.claude/settings.json`.
- [ ] Confirmar que o pacote não inclui `settings.json`, `settings-*.json` nem API keys.

## macOS

- [ ] Gerar `.app`.
- [ ] Gerar `.dmg`.
- [ ] Testar em Mac real.
- [ ] Confirmar que o app abre corretamente.
- [ ] Confirmar comportamento do Gatekeeper caso o app ainda não esteja assinado/notarizado.
- [ ] Confirmar leitura/gravação em `~/.claude/settings.json`.
- [ ] Confirmar que o pacote não inclui `settings.json`, `settings-*.json` nem API keys.

## Critérios de aceite

- O usuário final consegue instalar e abrir o app na plataforma testada.
- O app preserva as configurações locais do usuário em `~/.claude`.
- Nenhum segredo ou arquivo local de teste é empacotado.
- O usuário configura as próprias chaves após instalar.

## Observações

- Windows já possui instalador NSIS `.exe` gerado e validado localmente.
- Linux/macOS devem ser tratados como validação separada antes de entrarem em release estável.
