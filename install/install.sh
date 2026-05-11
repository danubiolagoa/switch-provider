#!/usr/bin/env bash
set -euo pipefail

REPO="${SWITCH_PROVIDER_REPO:-danubiolagoa/switch-provider}"
API_URL="https://api.github.com/repos/${REPO}/releases/latest"

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Comando obrigatorio nao encontrado: $1" >&2
    exit 1
  }
}

download_url() {
  local pattern="$1"
  python3 - "$API_URL" "$pattern" <<'PY'
import json
import re
import sys
from urllib.request import Request, urlopen

api_url, pattern = sys.argv[1], sys.argv[2]
request = Request(api_url, headers={"User-Agent": "switch-provider-installer"})
with urlopen(request) as response:
    data = json.load(response)

for asset in data.get("assets", []):
    if re.search(pattern, asset.get("name", "")):
        print(asset["browser_download_url"])
        print(asset["name"], file=sys.stderr)
        sys.exit(0)

sys.exit(1)
PY
}

need_cmd python3
need_cmd curl

OS="$(uname -s)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

case "$OS" in
  Linux)
    if command -v apt-get >/dev/null 2>&1; then
      URL="$(download_url '\.deb$')" || URL=""
      if [ -n "$URL" ]; then
        FILE="$TMP_DIR/switch-provider.deb"
        echo "Baixando pacote .deb..."
        curl -fL "$URL" -o "$FILE"
        echo "Instalando com apt..."
        sudo apt install -y "$FILE"
        exit 0
      fi
    fi

    URL="$(download_url '\.AppImage$')" || {
      echo "Nenhum .deb ou .AppImage encontrado na ultima release." >&2
      exit 1
    }
    TARGET="$HOME/.local/bin/switch-provider"
    mkdir -p "$HOME/.local/bin"
    echo "Baixando AppImage..."
    curl -fL "$URL" -o "$TARGET"
    chmod +x "$TARGET"
    echo "Instalado em $TARGET"
    ;;

  Darwin)
    URL="$(download_url '\.dmg$')" || {
      echo "Nenhum .dmg encontrado na ultima release." >&2
      exit 1
    }
    FILE="$TMP_DIR/switch-provider.dmg"
    MOUNT_DIR="$TMP_DIR/mount"
    mkdir -p "$MOUNT_DIR"
    echo "Baixando DMG..."
    curl -fL "$URL" -o "$FILE"
    echo "Montando DMG..."
    hdiutil attach "$FILE" -mountpoint "$MOUNT_DIR" -nobrowse -quiet
    APP_PATH="$(find "$MOUNT_DIR" -maxdepth 1 -name '*.app' -print -quit)"
    if [ -z "$APP_PATH" ]; then
      hdiutil detach "$MOUNT_DIR" -quiet || true
      echo "Nenhum .app encontrado dentro do DMG." >&2
      exit 1
    fi
    echo "Copiando para /Applications..."
    if [ -w /Applications ]; then
      rm -rf "/Applications/$(basename "$APP_PATH")"
      cp -R "$APP_PATH" /Applications/
    else
      sudo rm -rf "/Applications/$(basename "$APP_PATH")"
      sudo cp -R "$APP_PATH" /Applications/
    fi
    hdiutil detach "$MOUNT_DIR" -quiet
    echo "Instalado em /Applications/$(basename "$APP_PATH")"
    ;;

  *)
    echo "Sistema nao suportado por este instalador: $OS" >&2
    exit 1
    ;;
esac
