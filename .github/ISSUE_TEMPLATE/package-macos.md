---
name: Gerar e validar instalador macOS
about: Ajude a gerar ou testar pacote macOS do Switch Provider
title: "Gerar e validar instalador macOS"
labels: packaging, help wanted, macos
assignees: ""
---

## Objetivo

Gerar e validar os instaladores macOS do Switch Provider a partir do workflow de release e/ou de build em Mac real.

## Tarefas

- [ ] Gerar `.app`.
- [ ] Gerar `.dmg`.
- [ ] Testar em Mac real.
- [ ] Confirmar que o app abre corretamente.
- [ ] Confirmar comportamento do Gatekeeper caso o app ainda não esteja assinado/notarizado.
- [ ] Confirmar leitura/gravação em `~/.claude/settings.json`.
- [ ] Confirmar que o pacote não inclui `settings.json`, `settings-*.json` nem API keys.

## Critérios de aceite

- O usuário final consegue instalar e abrir o app no macOS.
- O app preserva as configurações locais do usuário em `~/.claude`.
- Nenhum segredo ou arquivo local de teste é empacotado.
- O usuário configura as próprias chaves após instalar.

## Observações

- Windows já possui instalador NSIS `.exe` gerado e validado localmente.
- macOS deve ser validado separadamente antes de entrar como download oficial.
