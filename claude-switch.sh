#!/bin/bash

CONFIG_DIR="$HOME/.claude"
SETTINGS="$CONFIG_DIR/settings.json"

show_menu() {
    clear
    echo ""
    echo "╔══════════════════════════════════════════════════╗"
    echo "║        Claude Code - Provider Manager           ║"
    echo "╠══════════════════════════════════════════════════╣"

    local count=0
    local files=()

    for f in "$CONFIG_DIR"/settings-*.json; do
        [ -f "$f" ] || continue
        count=$((count + 1))
        local name
        name=$(basename "$f" .json | sed 's/settings-//')
        files+=("$name")
        printf "║  [%s] %-44s║\n" "$count" "$name"
    done

    echo "╠══════════════════════════════════════════════════╣"
    echo "║  [a] Adicionar novo provider                    ║"
    echo "║  [r] Remover provider                          ║"
    echo "║  [v] Ver provider atual                        ║"
    echo "║  [0] Sair                                      ║"
    echo "╚══════════════════════════════════════════════════╝"
    echo ""

    if [ -f "$SETTINGS" ]; then
        local url
        url=$(grep -o '"ANTHROPIC_BASE_URL": *"[^"]*"' "$SETTINGS" 2>/dev/null | cut -d'"' -f4)
        if [ -n "$url" ]; then
            echo " Ativo agora: $url"
        else
            grep -q "ANTHROPIC_API_KEY" "$SETTINGS" && echo " Ativo agora: Anthropic (nativo)"
        fi
        echo ""
    fi

    echo -n " Escolha uma opção: "
    read -r choice

    case "$choice" in
        0) clear; echo " Até logo!"; echo ""; exit 0 ;;
        a) add_provider ;;
        r) remove_provider ;;
        v) view_current ;;
        *)
            if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "$count" ]; then
                local selected="${files[$((choice - 1))]}"
                activate_provider "$selected"
            else
                show_menu
            fi
            ;;
    esac
}

activate_provider() {
    local name="$1"
    clear
    echo ""
    echo " Ativando $name..."
    cp "$CONFIG_DIR/settings-$name.json" "$SETTINGS"
    echo " [OK] Provider ativo: $name"
    echo ""
    read -rp " Pressione Enter para continuar..."
    show_menu
}

add_provider() {
    clear
    echo ""
    echo "╔══════════════════════════════════════════════════╗"
    echo "║           Adicionar Novo Provider               ║"
    echo "╠══════════════════════════════════════════════════╣"
    echo "║                                                  ║"
    echo "║  Endpoints pre-configurados:                    ║"
    echo "║  [1] MiniMax        api.minimax.io/anthropic    ║"
    echo "║  [2] OpenRouter     openrouter.ai/api/v1        ║"
    echo "║  [3] Anthropic      (API key oficial)           ║"
    echo "║  [4] Z.AI / GLM     api.z.ai/api/anthropic      ║"
    echo "║  [5] Outro          (digitar manualmente)       ║"
    echo "║                                                  ║"
    echo "╚══════════════════════════════════════════════════╝"
    echo ""
    echo -n " Escolha o endpoint: "
    read -r ep_choice

    local base_url default_model default_name native=false

    case "$ep_choice" in
        1) base_url="https://api.minimax.io/anthropic"; default_model="MiniMax-M2.7"; default_name="minimax" ;;
        2) base_url="https://openrouter.ai/api/v1"; default_model="qwen/qwen3-235b-a22b:free"; default_name="openrouter" ;;
        3) native=true; default_model="claude-sonnet-4-20250514"; default_name="anthropic" ;;
        4) base_url="https://api.z.ai/api/anthropic"; default_model="GLM-4.7"; default_name="glm" ;;
        5)
            echo ""
            echo -n " Digite o endpoint: "
            read -r base_url
            default_name="custom"
            ;;
    esac

    echo ""
    echo -n " Nome para este provider [$default_name]: "
    read -r provider_name
    [ -z "$provider_name" ] && provider_name="$default_name"

    echo ""
    echo -n " Cole sua API Key: "
    read -r api_key

    local model_name="$default_model"
    if [ "$native" = false ]; then
        echo ""
        echo -n " Modelo principal [$default_model]: "
        read -r model_name
        [ -z "$model_name" ] && model_name="$default_model"
    fi

    local out_file="$CONFIG_DIR/settings-$provider_name.json"

    if [ "$native" = true ]; then
        cat > "$out_file" << EOF
{
  "env": {
    "ANTHROPIC_API_KEY": "$api_key",
    "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC": "1"
  },
  "autoUpdatesChannel": "latest"
}
EOF
    else
        cat > "$out_file" << EOF
{
  "env": {
    "ANTHROPIC_BASE_URL": "$base_url",
    "ANTHROPIC_AUTH_TOKEN": "$api_key",
    "API_TIMEOUT_MS": "3000000",
    "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC": "1",
    "ANTHROPIC_MODEL": "$model_name",
    "ANTHROPIC_SMALL_FAST_MODEL": "$model_name",
    "ANTHROPIC_DEFAULT_SONNET_MODEL": "$model_name",
    "ANTHROPIC_DEFAULT_OPUS_MODEL": "$model_name",
    "ANTHROPIC_DEFAULT_HAIKU_MODEL": "$model_name"
  },
  "autoUpdatesChannel": "latest"
}
EOF
    fi

    echo ""
    echo " [OK] Provider \"$provider_name\" salvo!"
    echo ""
    echo -n " Ativar agora? (s/n): "
    read -r ativar
    if [[ "$ativar" =~ ^[Ss]$ ]]; then
        cp "$out_file" "$SETTINGS"
        echo " [OK] Provider \"$provider_name\" ativado!"
    fi

    echo ""
    read -rp " Pressione Enter para continuar..."
    show_menu
}

remove_provider() {
    clear
    echo ""
    echo " Qual provider deseja remover?"
    echo ""

    local count=0
    local files=()

    for f in "$CONFIG_DIR"/settings-*.json; do
        [ -f "$f" ] || continue
        count=$((count + 1))
        local name
        name=$(basename "$f" .json | sed 's/settings-//')
        files+=("$name")
        echo " [$count] $name"
    done

    echo " [0] Cancelar"
    echo ""
    echo -n " Escolha: "
    read -r rdel

    if [ "$rdel" = "0" ] || [ -z "$rdel" ]; then
        show_menu
        return
    fi

    if [[ "$rdel" =~ ^[0-9]+$ ]] && [ "$rdel" -ge 1 ] && [ "$rdel" -le "$count" ]; then
        local selected="${files[$((rdel - 1))]}"
        echo ""
        echo -n " Remover \"$selected\"? (s/n): "
        read -r confirm
        if [[ "$confirm" =~ ^[Ss]$ ]]; then
            rm "$CONFIG_DIR/settings-$selected.json"
            echo " [OK] Provider removido."
        fi
    fi

    echo ""
    read -rp " Pressione Enter para continuar..."
    show_menu
}

view_current() {
    clear
    echo ""
    echo " settings.json atual:"
    echo " ────────────────────────────────────────"
    if [ -f "$SETTINGS" ]; then
        cat "$SETTINGS"
    else
        echo " [!] settings.json não encontrado!"
    fi
    echo ""
    read -rp " Pressione Enter para continuar..."
    show_menu
}

# Verifica se a pasta .claude existe
if [ ! -d "$CONFIG_DIR" ]; then
    mkdir -p "$CONFIG_DIR"
fi

show_menu
