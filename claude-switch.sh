#!/bin/bash

CONFIG_DIR="$HOME/.claude"
SETTINGS="$CONFIG_DIR/settings.json"

MENU_TOP="╔══════════════════════════════════════════════════╗"
MENU_MID="╠══════════════════════════════════════════════════╣"
MENU_BOTTOM="╚══════════════════════════════════════════════════╝"

menu_line() {
    local text="$1"
    printf "║ %-48.48s ║\n" "$text"
}

show_menu() {
    clear
    echo ""
    echo "$MENU_TOP"
    menu_line "       Claude Code - Provider Manager"
    echo "$MENU_MID"

    local count=0
    local files=()
    local current_label=""
    local current_provider="nenhum"
    local current_model=""
    local current_base_url=""

    for f in "$CONFIG_DIR"/settings-*.json; do
        [ -f "$f" ] || continue
        local base
        base=$(basename "$f" .json)
        [ "$base" = "settings-before-native-anthropic" ] && continue
        count=$((count + 1))
        local name
        name=$(printf "%s" "$base" | sed 's/settings-//')
        files+=("$name")
        if [ -f "$SETTINGS" ] && cmp -s "$f" "$SETTINGS"; then
            current_label="$name"
        fi
    done

    if [ -n "$current_label" ]; then
        current_provider="$current_label"
    elif [ -f "$SETTINGS" ]; then
        if grep -q '"ANTHROPIC_BASE_URL"' "$SETTINGS" 2>/dev/null; then
            current_provider="custom (base_url)"
        elif grep -q '"ANTHROPIC_API_KEY"' "$SETTINGS" 2>/dev/null; then
            current_provider="anthropic (api key)"
        else
            current_provider="claude padrao (anthropic login)"
        fi
    fi

    if [ -f "$SETTINGS" ]; then
        if command -v jq >/dev/null 2>&1; then
            current_model=$(jq -r '.env.ANTHROPIC_MODEL // empty' "$SETTINGS" 2>/dev/null)
            current_base_url=$(jq -r '.env.ANTHROPIC_BASE_URL // empty' "$SETTINGS" 2>/dev/null)
        else
            current_model=$(grep -o '"ANTHROPIC_MODEL": *"[^"]*"' "$SETTINGS" 2>/dev/null | head -1 | cut -d'"' -f4)
            current_base_url=$(grep -o '"ANTHROPIC_BASE_URL": *"[^"]*"' "$SETTINGS" 2>/dev/null | head -1 | cut -d'"' -f4)
        fi
    fi

    if [ "$count" -eq 0 ]; then
        menu_line " Nenhum provider configurado ainda."
    else
        local i=1
        while [ "$i" -le "$count" ]; do
            local name="${files[$((i - 1))]}"
            if [ "$name" = "$current_label" ]; then
                menu_line " [$i] $name  [v] ativo"
            else
                menu_line " [$i] $name"
            fi
            i=$((i + 1))
        done
    fi

    echo "$MENU_MID"
    menu_line " [a] Adicionar novo provider"
    menu_line " [r] Remover provider"
    case "$current_base_url" in
        *openrouter.ai*) menu_line " [m] Trocar modelo OpenRouter" ;;
    esac
    menu_line " [n] Claude padrao (Anthropic login)"
    menu_line " [v] Ver provider atual"
    menu_line " [0] Sair"
    echo "$MENU_BOTTOM"
    echo ""
    echo " Ativo: $current_provider"
    [ -n "$current_model" ] && echo " Modelo: $current_model"
    echo ""

    echo -n " Escolha uma opcao: "
    read -r choice

    case "$choice" in
        0) clear; echo " Ate logo!"; echo ""; exit 0 ;;
        a) add_provider ;;
        r) remove_provider ;;
        m) change_openrouter_model ;;
        n) use_native_anthropic ;;
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
    local tmp_settings="${SETTINGS}.tmp.$$"
    cp "$CONFIG_DIR/settings-$name.json" "$tmp_settings" && mv "$tmp_settings" "$SETTINGS"
    echo ""
    echo "╔══════════════════════════════════════════════════╗"
    echo "║  [OK] Provider ativo: $name"
    echo "╠══════════════════════════════════════════════════╣"
    echo "║                                                  ║"
    echo "║  IMPORTANTE: Para aplicar a mudanca, voce      ║"
    echo "║  precisa REINICIAR o Claude Code.              ║"
    echo "║                                                  ║"
    echo "║  Feche e abra novamente o Claude Code para     ║"
    echo "║  comecar a usar o novo provider.               ║"
    echo "║                                                  ║"
    echo "╚══════════════════════════════════════════════════╝"
    echo ""
    read -rp " Pressione Enter para continuar..."
    show_menu
}

use_native_anthropic() {
    clear
    echo ""
    echo " Ativando Claude Code padrao (Anthropic login)..."

    if [ -f "$SETTINGS" ]; then
        cp "$SETTINGS" "$CONFIG_DIR/settings-before-native-anthropic.json"
    fi

    local tmp_settings="${SETTINGS}.tmp.$$"
    cat > "$tmp_settings" << EOF
{
  "env": {
    "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC": "1"
  },
  "autoUpdatesChannel": "latest"
}
EOF
    mv "$tmp_settings" "$SETTINGS"

    echo ""
    echo "╔══════════════════════════════════════════════════╗"
    echo "║  [OK] Claude Code padrao ativado                ║"
    echo "╠══════════════════════════════════════════════════╣"
    echo "║  Proximos passos:                               ║"
    echo "║  1) Reinicie o Claude Code                      ║"
    echo "║  2) Rode /login ou claude login                 ║"
    echo "║  3) Selecione Anthropic                         ║"
    echo "╚══════════════════════════════════════════════════╝"
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
    echo "║  [2] OpenRouter     openrouter.ai/api           ║"
    echo "║  [3] Anthropic      (API key oficial)           ║"
    echo "║  [4] Z.AI / GLM     api.z.ai/api/anthropic      ║"
    echo "║  [5] Google AI Studio (Gemini)                 ║"
    echo "║  [6] OpenAI (GPT)                              ║"
    echo "║  [7] Outro          (digitar manualmente)       ║"
    echo "║                                                  ║"
    echo "╚══════════════════════════════════════════════════╝"
    echo ""
    echo -n " Escolha o endpoint: "
    read -r ep_choice

    local base_url default_model default_name native=false needs_models=false

    case "$ep_choice" in
        1) base_url="https://api.minimax.io/anthropic"; default_model="MiniMax-M2.7"; default_name="minimax" ;;
        2) base_url="https://openrouter.ai/api"; default_model=""; default_name="openrouter"; needs_models=true ;;
        3) native=true; default_model="claude-sonnet-4-20250514"; default_name="anthropic" ;;
        4) base_url="https://api.z.ai/api/anthropic"; default_model="GLM-4.7"; default_name="glm" ;;
        5) base_url="https://generativelanguage.googleapis.com"; default_model="gemini-2.0-flash"; default_name="gemini"; needs_models=true ;;
        6) base_url="https://api.openai.com/v1"; default_model="gpt-4o-mini"; default_name="openai"; needs_models=true ;;
        7)
            echo ""
            echo -n " Digite o endpoint: "
            read -r base_url
            default_name="custom"
            needs_models=true
            ;;
    esac

    echo ""
    echo -n " Nome para este provider [$default_name]: "
    read -r provider_name
    [ -z "$provider_name" ] && provider_name="$default_name"
    provider_name=$(printf "%s" "$provider_name" | sed 's/[\\\/:*?"<>|]/-/g; s/^[[:space:]]*//; s/[[:space:]]*$//')
    [ -z "$provider_name" ] && provider_name="$default_name"

    echo ""
    echo -n " Cole sua API Key: "
    read -r api_key
    api_key=$(printf "%s" "$api_key" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

    local model_selected=""

    if [ "$needs_models" = true ]; then
        case "$ep_choice" in
            2)
                if ! validate_openrouter_key "$api_key"; then
                    echo ""
                    echo " [OK] Operacao cancelada."
                    echo ""
                    read -rp " Pressione Enter para continuar..."
                    show_menu
                    return
                fi
                if select_openrouter_model "$api_key"; then
                    model_selected="$SELECTED_MODEL"
                fi
                ;;
            5)
                if select_gemini_model "$api_key"; then
                    model_selected="$SELECTED_MODEL"
                fi
                ;;
            6)
                if select_openai_model "$api_key"; then
                    model_selected="$SELECTED_MODEL"
                fi
                ;;
        esac

        if [ -z "$model_selected" ]; then
            echo ""
            echo -n " Digite manualmente o ID do modelo (ENTER para cancelar): "
            read -r model_selected
            model_selected=$(printf "%s" "$model_selected" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
            if [ -z "$model_selected" ]; then
                echo ""
                echo " [OK] Operacao cancelada."
                echo ""
                read -rp " Pressione Enter para continuar..."
                show_menu
                return
            fi
        fi
    fi

    # Modelos para cada slot - usa o mesmo para todos quando precisa de modelos
    local model_main="$default_model"
    local model_fast="$default_model"
    local model_sonnet="$default_model"
    local model_opus="$default_model"
    local model_haiku="$default_model"

    if [ "$needs_models" = true ]; then
        model_main="$model_selected"
        model_fast="$model_selected"
        model_sonnet="$model_selected"
        model_opus="$model_selected"
        model_haiku="$model_selected"
    fi

    # Confirmacao final
    clear
    echo ""
    echo "╔══════════════════════════════════════════════════╗"
    echo "║         Confirmar Configuracao                  ║"
    echo "╠══════════════════════════════════════════════════╣"
    echo "║  Provider: $provider_name"
    echo "║  Endpoint: $base_url"
    echo "╠══════════════════════════════════════════════════╣"
    echo "║  Modelos selecionados:                          ║"
    echo "║  Principal:   $model_main"
    echo "║  Rapido:      $model_fast"
    echo "║  Sonnet:      $model_sonnet"
    echo "║  Opus:        $model_opus"
    echo "║  Haiku:       $model_haiku"
    echo "╠══════════════════════════════════════════════════╣"
    echo "║                                                  ║"
    echo "║  [ENTER] Confirmar e salvar                     ║"
    echo "║  [n] Cancelar e voltar ao menu                 ║"
    echo "╚══════════════════════════════════════════════════╝"
    echo ""
    echo -n " Escolha: "
    read -r confirm

    if [[ "$confirm" =~ ^[Nn]$ ]]; then
        show_menu
        return
    fi

    local out_file="$CONFIG_DIR/settings-$provider_name.json"
    local tmp_out_file="${out_file}.tmp.$$"

    if [ "$native" = true ]; then
        cat > "$tmp_out_file" << EOF
{
  "env": {
    "ANTHROPIC_API_KEY": "$api_key",
    "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC": "1"
  },
  "autoUpdatesChannel": "latest"
}
EOF
    else
        cat > "$tmp_out_file" << EOF
{
  "env": {
    "ANTHROPIC_BASE_URL": "$base_url",
    "ANTHROPIC_AUTH_TOKEN": "$api_key",
    "ANTHROPIC_API_KEY": "",
    "API_TIMEOUT_MS": "3000000",
    "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC": "1",
    "ANTHROPIC_MODEL": "$model_main",
    "ANTHROPIC_SMALL_FAST_MODEL": "$model_fast",
    "ANTHROPIC_DEFAULT_SONNET_MODEL": "$model_sonnet",
    "ANTHROPIC_DEFAULT_OPUS_MODEL": "$model_opus",
    "ANTHROPIC_DEFAULT_HAIKU_MODEL": "$model_haiku"
  },
  "autoUpdatesChannel": "latest"
}
EOF
    fi
    mv "$tmp_out_file" "$out_file"

    echo ""
    echo " [OK] Provider \"$provider_name\" salvo!"
    echo ""
    echo -n " Ativar agora? (s/n): "
    read -r ativar
    if [[ "$ativar" =~ ^[Ss]$ ]]; then
        local tmp_settings="${SETTINGS}.tmp.$$"
        cp "$out_file" "$tmp_settings" && mv "$tmp_settings" "$SETTINGS"
        echo ""
        echo "╔══════════════════════════════════════════════════╗"
        echo "║  [OK] Provider \"$provider_name\" ativado!"
        echo "╠══════════════════════════════════════════════════╣"
        echo "║  IMPORTANTE: Reinicie o Claude Code para        ║"
        echo "║  aplicar a mudanca!                             ║"
        echo "╚══════════════════════════════════════════════════╝"
    fi

    echo ""
    read -rp " Pressione Enter para continuar..."
    show_menu
}

# ---------------------------------------------------------------
# Selecao de modelos via API
# ---------------------------------------------------------------

validate_openrouter_key() {
    local api_key="$1"
    local response
    local response_file
    response_file=$(mktemp)
    local http_code
    http_code=$(curl -s -m 20 -w "%{http_code}" "https://openrouter.ai/api/v1/key" \
        -H "Authorization: Bearer $api_key" \
        -o "$response_file" 2>/dev/null)
    response=$(cat "$response_file" 2>/dev/null)
    rm -f "$response_file"

    if [ "$http_code" = "200" ]; then
        return 0
    fi

    local api_error=""
    if command -v jq &> /dev/null; then
        api_error=$(echo "$response" | jq -r '.error.message // .error // empty' 2>/dev/null)
    fi
    [ -z "$api_error" ] && api_error="Falha na autenticacao OpenRouter (HTTP $http_code)."

    clear
    echo ""
    echo "╔══════════════════════════════════════════════════╗"
    echo "║  [ERRO] Chave OpenRouter invalida ou sem acesso ║"
    echo "╠══════════════════════════════════════════════════╣"
    echo "║  $api_error"
    echo "╚══════════════════════════════════════════════════╝"
    echo ""
    return 1
}

select_openrouter_model() {
    local api_key="$1"
    SELECTED_MODEL=""
    clear
    echo ""
    echo "╔══════════════════════════════════════════════════╗"
    echo "║       Selecionar Modelo - OpenRouter           ║"
    echo "╠══════════════════════════════════════════════════╣"
    echo "║  Buscando modelos..."

    local response
    local response_file
    response_file=$(mktemp)
    local http_code
    http_code=$(curl -s -m 30 -w "%{http_code}" "https://openrouter.ai/api/v1/models" \
        -H "Authorization: Bearer $api_key" \
        -o "$response_file" 2>/dev/null)
    response=$(cat "$response_file" 2>/dev/null)
    rm -f "$response_file"

    if [ -z "$response" ]; then
        echo "║  [ERRO] Falha ao buscar modelos. Verifique    ║"
        echo "║  a API Key ou conexao.                        ║"
        echo "╚══════════════════════════════════════════════════╝"
        echo ""
        return 1
    fi

    # Verifica se jq esta disponivel
    if ! command -v jq &> /dev/null; then
        echo "║  [ERRO] jq nao instalado. necessario para     ║"
        echo "║  processar modelos. Instale jq primeiro.    ║"
        echo "╚══════════════════════════════════════════════════╝"
        echo ""
        return 1
    fi

    # Se houve erro HTTP, mostra o detalhe da API
    if [ "$http_code" != "200" ]; then
        local http_error
        http_error=$(echo "$response" | jq -r '.error.message // .error // empty' 2>/dev/null)
        [ -z "$http_error" ] && http_error="HTTP $http_code ao buscar modelos."
        echo "║  [ERRO] $http_error"
        echo "╚══════════════════════════════════════════════════╝"
        echo ""
        return 1
    fi

    # Se a API retornou erro estruturado, mostra a mensagem real
    local api_error
    api_error=$(echo "$response" | jq -r '.error.message // .error // empty' 2>/dev/null)
    if [ -n "$api_error" ]; then
        echo "║  [ERRO] $api_error"
        echo "╚══════════════════════════════════════════════════╝"
        echo ""
        return 1
    fi

    # Extrai modelos e salva em arquivo temporario.
    local tmp_file
    tmp_file=$(mktemp)
    echo "$response" | jq -r '.data[] | "\(.id)|\(.name // .id)"' 2>/dev/null > "$tmp_file"

    if [ ! -s "$tmp_file" ]; then
        echo "║  [ERRO] Nenhum modelo encontrado.             ║"
        echo "╚══════════════════════════════════════════════════╝"
        rm -f "$tmp_file"
        echo ""
        return 1
    fi

    local total_models=$(wc -l < "$tmp_file")
    echo "║  Encontrados $total_models modelos              ║"
    echo "║  Aviso: modelos free podem retornar 429.        ║"
    echo "╚══════════════════════════════════════════════════╝"
    echo ""

    local page=0
    local page_size=10
    local total_pages=$(( (total_models + page_size - 1) / page_size ))

    while true; do
        clear
        echo ""
        echo "╔══════════════════════════════════════════════════╗"
        echo "║       Selecionar Modelo - OpenRouter           ║"
        echo "╠══════════════════════════════════════════════════╣"
        echo "║  Pagina $((page + 1)) de $total_pages                       ║"
        echo "╠══════════════════════════════════════════════════╣"

        local start=$((page * page_size + 1))
        local end=$((start + page_size - 1))
        if [ "$end" -gt "$total_models" ]; then
            end=$total_models
        fi

        local count=0
        local display_items=()
        while IFS='|' read -r model_id model_name; do
            count=$((count + 1))
            if [ "$count" -ge "$start" ] && [ "$count" -le "$end" ]; then
                display_items+=("$model_id|$model_name")
                printf "║  [%s] %-47s║\n" "$count" "$model_name"
            fi
        done < "$tmp_file"

        echo "╠══════════════════════════════════════════════════╣"
        echo "║  [p] Proxima pagina                             ║"
        echo "║  [a] Pagina anterior                            ║"
        echo "║  [0] Cancelar                                   ║"
        echo "╚══════════════════════════════════════════════════╝"
        echo ""
        echo -n " Escolha: "
        if ! read -r choice; then
            rm -f "$tmp_file"
            return 1
        fi

        case "$choice" in
            0) rm -f "$tmp_file"; return 1 ;;
            p|P)
                if [ "$page" -lt $((total_pages - 1)) ]; then
                    page=$((page + 1))
                fi
                ;;
            a|A)
                if [ "$page" -gt 0 ]; then
                    page=$((page - 1))
                fi
                ;;
            *)
                if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "$total_models" ]; then
                    local selected=$(sed -n "${choice}p" "$tmp_file")
                    local selected_id=$(echo "$selected" | cut -d'|' -f1)
                    rm -f "$tmp_file"
                    SELECTED_MODEL="$selected_id"
                    return 0
                fi
                ;;
        esac
    done
}

select_gemini_model() {
    local api_key="$1"
    SELECTED_MODEL=""
    clear
    echo ""
    echo "╔══════════════════════════════════════════════════╗"
    echo "║       Selecionar Modelo - Google AI Studio      ║"
    echo "╠══════════════════════════════════════════════════╣"
    echo "║  Buscando modelos..."

    local response
    local response_file
    response_file=$(mktemp)
    local http_code
    http_code=$(curl -s -m 30 -w "%{http_code}" "https://generativelanguage.googleapis.com/v1beta/models" \
        -H "X-goog-api-key: $api_key" \
        -o "$response_file" 2>/dev/null)
    response=$(cat "$response_file" 2>/dev/null)
    rm -f "$response_file"

    if [ -z "$response" ]; then
        echo "║  [ERRO] Falha ao buscar modelos. Verifique    ║"
        echo "║  a API Key ou conexao.                        ║"
        echo "╚══════════════════════════════════════════════════╝"
        echo ""
        return 1
    fi

    if ! command -v jq &> /dev/null; then
        echo "║  [ERRO] jq nao instalado. necessario para     ║"
        echo "║  processar modelos. Instale jq primeiro.      ║"
        echo "╚══════════════════════════════════════════════════╝"
        echo ""
        return 1
    fi

    if [ "$http_code" != "200" ]; then
        local http_error
        http_error=$(echo "$response" | jq -r '.error.message // .error.status // .error // empty' 2>/dev/null)
        [ -z "$http_error" ] && http_error="HTTP $http_code ao buscar modelos."
        echo "║  [ERRO] $http_error"
        echo "╚══════════════════════════════════════════════════╝"
        echo ""
        return 1
    fi

    local tmp_file
    tmp_file=$(mktemp)
    echo "$response" | jq -r '.models[] | "\(.name|sub("^models/";""))|\(.displayName // .name)"' 2>/dev/null > "$tmp_file"

    if [ ! -s "$tmp_file" ]; then
        echo "║  [ERRO] Nenhum modelo encontrado.             ║"
        echo "╚══════════════════════════════════════════════════╝"
        rm -f "$tmp_file"
        echo ""
        return 1
    fi

    local total_models=$(wc -l < "$tmp_file")
    echo "║  Encontrados $total_models modelos              ║"
    echo "╚══════════════════════════════════════════════════╝"
    echo ""

    local page=0
    local page_size=10
    local total_pages=$(( (total_models + page_size - 1) / page_size ))

    while true; do
        clear
        echo ""
        echo "╔══════════════════════════════════════════════════╗"
        echo "║       Selecionar Modelo - Google AI Studio      ║"
        echo "╠══════════════════════════════════════════════════╣"
        echo "║  Pagina $((page + 1)) de $total_pages                       ║"
        echo "╠══════════════════════════════════════════════════╣"

        local start=$((page * page_size + 1))
        local end=$((start + page_size - 1))
        if [ "$end" -gt "$total_models" ]; then
            end=$total_models
        fi

        local count=0
        local display_items=()
        while IFS='|' read -r model_name model_display; do
            count=$((count + 1))
            if [ "$count" -ge "$start" ] && [ "$count" -le "$end" ]; then
                display_items+=("$model_name|$model_display")
                printf "║  [%s] %-47s║\n" "$count" "$model_display"
            fi
        done < "$tmp_file"

        echo "╠══════════════════════════════════════════════════╣"
        echo "║  [p] Proxima pagina                             ║"
        echo "║  [a] Pagina anterior                            ║"
        echo "║  [0] Cancelar                                   ║"
        echo "╚══════════════════════════════════════════════════╝"
        echo ""
        echo -n " Escolha: "
        if ! read -r choice; then
            rm -f "$tmp_file"
            return 1
        fi

        case "$choice" in
            0) rm -f "$tmp_file"; return 1 ;;
            p|P)
                if [ "$page" -lt $((total_pages - 1)) ]; then
                    page=$((page + 1))
                fi
                ;;
            a|A)
                if [ "$page" -gt 0 ]; then
                    page=$((page - 1))
                fi
                ;;
            *)
                if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "$total_models" ]; then
                    local selected=$(sed -n "${choice}p" "$tmp_file")
                    local selected_id=$(echo "$selected" | cut -d'|' -f1)
                    # Remove prefixo "models/" se existir
                    selected_id=$(echo "$selected_id" | sed 's/^models\///')
                    rm -f "$tmp_file"
                    SELECTED_MODEL="$selected_id"
                    return 0
                fi
                ;;
        esac
    done
}

select_openai_model() {
    local api_key="$1"
    SELECTED_MODEL=""
    clear
    echo ""
    echo "╔══════════════════════════════════════════════════╗"
    echo "║         Selecionar Modelo - OpenAI               ║"
    echo "╠══════════════════════════════════════════════════╣"
    echo "║  Buscando modelos..."

    local response
    local response_file
    response_file=$(mktemp)
    local http_code
    http_code=$(curl -s -m 30 -w "%{http_code}" "https://api.openai.com/v1/models" \
        -H "Authorization: Bearer $api_key" \
        -o "$response_file" 2>/dev/null)
    response=$(cat "$response_file" 2>/dev/null)
    rm -f "$response_file"

    if [ -z "$response" ]; then
        echo "║  [ERRO] Falha ao buscar modelos. Verifique    ║"
        echo "║  a API Key ou conexao.                        ║"
        echo "╚══════════════════════════════════════════════════╝"
        echo ""
        return 1
    fi

    if ! command -v jq &> /dev/null; then
        echo "║  [ERRO] jq nao instalado. necessario para     ║"
        echo "║  processar modelos. Instale jq primeiro.      ║"
        echo "╚══════════════════════════════════════════════════╝"
        echo ""
        return 1
    fi

    if [ "$http_code" != "200" ]; then
        local http_error
        http_error=$(echo "$response" | jq -r '.error.message // .error.code // .error // empty' 2>/dev/null)
        [ -z "$http_error" ] && http_error="HTTP $http_code ao buscar modelos."
        echo "║  [ERRO] $http_error"
        echo "╚══════════════════════════════════════════════════╝"
        echo ""
        return 1
    fi

    local tmp_file
    tmp_file=$(mktemp)
    echo "$response" | jq -r '.data[] | "\(.id)"' 2>/dev/null > "$tmp_file"

    if [ ! -s "$tmp_file" ]; then
        echo "║  [ERRO] Nenhum modelo encontrado.             ║"
        echo "╚══════════════════════════════════════════════════╝"
        rm -f "$tmp_file"
        echo ""
        return 1
    fi

    local total_models=$(wc -l < "$tmp_file")
    echo "║  Encontrados $total_models modelos              ║"
    echo "╚══════════════════════════════════════════════════╝"
    echo ""

    local page=0
    local page_size=10
    local total_pages=$(( (total_models + page_size - 1) / page_size ))

    while true; do
        clear
        echo ""
        echo "╔══════════════════════════════════════════════════╗"
        echo "║         Selecionar Modelo - OpenAI               ║"
        echo "╠══════════════════════════════════════════════════╣"
        echo "║  Pagina $((page + 1)) de $total_pages                       ║"
        echo "╠══════════════════════════════════════════════════╣"

        local start=$((page * page_size + 1))
        local end=$((start + page_size - 1))
        if [ "$end" -gt "$total_models" ]; then
            end=$total_models
        fi

        local count=0
        local display_items=()
        while IFS= read -r model_id; do
            count=$((count + 1))
            if [ "$count" -ge "$start" ] && [ "$count" -le "$end" ]; then
                display_items+=("$model_id")
                printf "║  [%s] %-47s║\n" "$count" "$model_id"
            fi
        done < "$tmp_file"

        echo "╠══════════════════════════════════════════════════╣"
        echo "║  [p] Proxima pagina                             ║"
        echo "║  [a] Pagina anterior                            ║"
        echo "║  [0] Cancelar                                   ║"
        echo "╚══════════════════════════════════════════════════╝"
        echo ""
        echo -n " Escolha: "
        if ! read -r choice; then
            rm -f "$tmp_file"
            return 1
        fi

        case "$choice" in
            0) rm -f "$tmp_file"; return 1 ;;
            p|P)
                if [ "$page" -lt $((total_pages - 1)) ]; then
                    page=$((page + 1))
                fi
                ;;
            a|A)
                if [ "$page" -gt 0 ]; then
                    page=$((page - 1))
                fi
                ;;
            *)
                if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "$total_models" ]; then
                    local selected_id=$(sed -n "${choice}p" "$tmp_file")
                    rm -f "$tmp_file"
                    SELECTED_MODEL="$selected_id"
                    return 0
                fi
                ;;
        esac
    done
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
        local base
        base=$(basename "$f" .json)
        [ "$base" = "settings-before-native-anthropic" ] && continue
        count=$((count + 1))
        local name
        name=$(printf "%s" "$base" | sed 's/settings-//')
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

change_openrouter_model() {
    clear
    echo ""

    if [ ! -f "$SETTINGS" ]; then
        echo " [ERRO] settings.json nao encontrado."
        echo ""
        read -rp " Pressione Enter para continuar..."
        show_menu
        return
    fi

    if ! command -v jq >/dev/null 2>&1; then
        echo " [ERRO] jq nao instalado. Necessario para atualizar o modelo."
        echo ""
        read -rp " Pressione Enter para continuar..."
        show_menu
        return
    fi

    local base_url
    local api_key
    local current_model
    base_url=$(jq -r '.env.ANTHROPIC_BASE_URL // empty' "$SETTINGS" 2>/dev/null)
    api_key=$(jq -r '.env.ANTHROPIC_AUTH_TOKEN // empty' "$SETTINGS" 2>/dev/null)
    current_model=$(jq -r '.env.ANTHROPIC_MODEL // empty' "$SETTINGS" 2>/dev/null)

    case "$base_url" in
        *openrouter.ai*) ;;
        *)
            echo " [ERRO] O provider ativo nao e OpenRouter."
            echo ""
            read -rp " Pressione Enter para continuar..."
            show_menu
            return
            ;;
    esac

    if [ -z "$api_key" ]; then
        echo " [ERRO] API key do OpenRouter nao encontrada no settings.json."
        echo ""
        read -rp " Pressione Enter para continuar..."
        show_menu
        return
    fi

    local active_provider_file=""
    for f in "$CONFIG_DIR"/settings-*.json; do
        [ -f "$f" ] || continue
        [ "$(basename "$f" .json)" = "settings-before-native-anthropic" ] && continue
        if cmp -s "$f" "$SETTINGS"; then
            active_provider_file="$f"
            break
        fi
    done

    echo " Modelo atual: ${current_model:-nao definido}"
    echo ""
    echo " Buscando modelos do OpenRouter..."

    local model_selected=""
    if select_openrouter_model "$api_key"; then
        model_selected="$SELECTED_MODEL"
    fi

    if [ -z "$model_selected" ]; then
        echo ""
        echo " [OK] Operacao cancelada."
        echo ""
        read -rp " Pressione Enter para continuar..."
        show_menu
        return
    fi

    clear
    echo ""
    echo " Modelo atual: ${current_model:-nao definido}"
    echo " Novo modelo:  $model_selected"
    echo ""
    echo -n " Confirmar troca? (s/n): "
    read -r confirm
    if ! [[ "$confirm" =~ ^[Ss]$ ]]; then
        show_menu
        return
    fi

    local tmp_settings
    tmp_settings="${SETTINGS}.tmp.$$"
    if ! jq --arg model "$model_selected" '
        .env.ANTHROPIC_MODEL = $model |
        .env.ANTHROPIC_SMALL_FAST_MODEL = $model |
        .env.ANTHROPIC_DEFAULT_SONNET_MODEL = $model |
        .env.ANTHROPIC_DEFAULT_OPUS_MODEL = $model |
        .env.ANTHROPIC_DEFAULT_HAIKU_MODEL = $model
    ' "$SETTINGS" > "$tmp_settings"; then
        rm -f "$tmp_settings"
        echo ""
        echo " [ERRO] Falha ao atualizar settings.json."
        echo ""
        read -rp " Pressione Enter para continuar..."
        show_menu
        return
    fi

    mv "$tmp_settings" "$SETTINGS"
    if [ -n "$active_provider_file" ]; then
        cp "$SETTINGS" "$active_provider_file"
    fi

    echo ""
    echo " [OK] Modelo OpenRouter atualizado."
    if [ -n "$active_provider_file" ]; then
        echo " [OK] Backup do provider ativo tambem foi atualizado."
    fi
    echo ""
    echo " IMPORTANTE: Reinicie o Claude Code para aplicar a mudanca."
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
        if command -v jq >/dev/null 2>&1; then
            jq '
              .env.ANTHROPIC_AUTH_TOKEN |= (if . then ((.[0:4] // "") + "****************************") else . end) |
              .env.ANTHROPIC_API_KEY |= (if . then ((.[0:4] // "") + "****************************") else . end)
            ' "$SETTINGS" 2>/dev/null || cat "$SETTINGS"
        else
            sed -E \
                's/"ANTHROPIC_AUTH_TOKEN":[[:space:]]*"([^"]{0,4})[^"]*"/"ANTHROPIC_AUTH_TOKEN": "\1****************************"/g; s/"ANTHROPIC_API_KEY":[[:space:]]*"([^"]{0,4})[^"]*"/"ANTHROPIC_API_KEY": "\1****************************"/g' \
                "$SETTINGS"
        fi
    else
        echo " [!] settings.json nao encontrado!"
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
