#!/bin/bash

CONFIG_DIR="$HOME/.claude"
SETTINGS="$CONFIG_DIR/settings.json"

# Cores ANSI
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
BLUE='\033[34m'
CYAN='\033[36m'
WHITE='\033[37m'
GRAY='\033[90m'
BOLD='\033[1m'
RESET='\033[0m'

# Separador visual
SEP="  ${GRAY}------------------------------------------------${RESET}"

show_menu() {
    clear
    echo ""
    echo -e "  ${BOLD}${BLUE}Claude Code - Provider Manager${RESET}"
    echo -e "$SEP"

    local count=0
    local files=()
    local current_label=""
    local current_provider="nenhum"
    local current_model=""
    local current_base_url=""

    for f in "$CONFIG_DIR"/settings-*.json; do
        [ -f "$f" ] || continue
        base=$(basename "$f" .json)
        [ "$base" = "settings-before-native-anthropic" ] && continue
        count=$((count + 1))
        name="${base#settings-}"
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
            current_provider="claude padrao (Anthropic login)"
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

    echo -e "  ${GRAY}provider:${RESET} ${WHITE}$current_provider${RESET}"
    echo ""

    if [ "$count" -eq 0 ]; then
        echo -e "  ${GRAY}Nenhum provider configurado.${RESET}"
    else
        echo -e "  ${GRAY}Providers:${RESET}"
        local i=1
        while [ "$i" -le "$count" ]; do
            name="${files[$((i - 1))]}"
            if [ "$name" = "$current_label" ]; then
                echo -e "    ${CYAN}[$i]${RESET} ${WHITE}$name${RESET} ${GREEN}[ativo]${RESET}"
            else
                echo -e "    ${CYAN}[$i]${RESET} ${WHITE}$name${RESET}"
            fi
            i=$((i + 1))
        done
    fi

    echo ""
    echo -e "$SEP"
    echo -e "  ${GRAY}[a]${RESET} Adicionar novo provider"
    echo -e "  ${GRAY}[r]${RESET} Remover provider"
    case "$current_base_url" in
        *openrouter.ai*) echo -e "  ${GRAY}[m]${RESET} Trocar modelo OpenRouter" ;;
    esac
    echo -e "  ${GRAY}[n]${RESET} Claude padrao (Anthropic login)"
    echo -e "  ${GRAY}[v]${RESET} Ver provider atual"
    echo -e "$SEP"
    echo -e "  ${GRAY}[0]${RESET} ${WHITE}Sair${RESET}"
    echo ""
    if [ -n "$current_model" ]; then
        echo -e "  ${GRAY}Modelo:${RESET} ${CYAN}$current_model${RESET}"
        echo ""
    fi
    echo -n "  Escolha: "
    read -r choice

    case "$choice" in
        0) clear; show_goodbye ;;
        a) add_provider ;;
        r) remove_provider ;;
        m) change_openrouter_model ;;
        n) use_native_anthropic ;;
        v) view_current ;;
        *)
            if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "$count" ]; then
                selected="${files[$((choice - 1))]}"
                activate_provider "$selected"
            else
                show_menu
            fi
            ;;
    esac
}

activate_provider() {
    clear
    echo ""
    echo -e "  ${GREEN}${BOLD}Provider ativado:${RESET} ${WHITE}$1${RESET}"
    echo ""
    echo -e "  ${YELLOW}Reinicie o Claude Code para aplicar.${RESET}"
    echo ""
    read -rp "  Pressione Enter para continuar... " tmp
    show_menu
}

use_native_anthropic() {
    clear
    echo ""
    echo -e "  ${GREEN}${BOLD}Anthropic nativo ativado${RESET}"
    echo ""
    echo -e "  ${GRAY}Proximos passos:${RESET}"
    echo -e "    ${WHITE}1.${RESET} ${GRAY}Reinicie o Claude Code${RESET}"
    echo -e "    ${WHITE}2.${RESET} ${GRAY}Rode /login ou claude login${RESET}"
    echo -e "    ${WHITE}3.${RESET} ${GRAY}Selecione Anthropic${RESET}"
    echo ""
    read -rp "  Pressione Enter para continuar... " tmp
    show_menu
}

add_provider() {
    clear
    echo ""
    echo -e "  ${BOLD}${BLUE}Adicionar Novo Provider${RESET}"
    echo -e "$SEP"
    echo -e "  ${GRAY}Selecione o endpoint:${RESET}"
    echo ""
    echo -e "  ${CYAN}[1]${RESET} ${WHITE}MiniMax${RESET}      ${GRAY}api.minimax.io/anthropic${RESET}"
    echo -e "  ${CYAN}[2]${RESET} ${WHITE}OpenRouter${RESET}   ${GRAY}openrouter.ai/api${RESET}"
    echo -e "  ${CYAN}[3]${RESET} ${WHITE}Anthropic${RESET}    ${GRAY}(API key oficial)${RESET}"
    echo -e "  ${CYAN}[4]${RESET} ${WHITE}Z.AI/GLM${RESET}     ${GRAY}api.z.ai/api/anthropic${RESET}"
    echo -e "  ${CYAN}[5]${RESET} ${WHITE}Google AI${RESET}    ${GRAY}generativelanguage.googleapis${RESET}"
    echo -e "  ${CYAN}[6]${RESET} ${WHITE}OpenAI${RESET}       ${GRAY}api.openai.com/v1${RESET}"
    echo -e "  ${CYAN}[7]${RESET} ${WHITE}Outro${RESET}        ${GRAY}(digitar manualmente)${RESET}"
    echo -e "  ${CYAN}[8]${RESET} ${WHITE}NVIDIA${RESET}       ${GRAY}integrate.api.nvidia.com${RESET}"
    echo ""
    echo -n "  Endpoint: "
    read -r ep_choice

    base_url="" default_model="" default_name="custom" native=false needs_models=false

    case "$ep_choice" in
        1) base_url="https://api.minimax.io/anthropic"; default_model="MiniMax-M2.7"; default_name="minimax" ;;
        2) base_url="https://openrouter.ai/api"; default_model=""; default_name="openrouter"; needs_models=true ;;
        3) native=true; default_model="claude-sonnet-4-20250514"; default_name="anthropic" ;;
        4) base_url="https://api.z.ai/api/anthropic"; default_model="GLM-4.7"; default_name="glm" ;;
        5) base_url="https://generativelanguage.googleapis.com"; default_model="gemini-2.0-flash"; default_name="gemini"; needs_models=true ;;
        6) base_url="https://api.openai.com/v1"; default_model="gpt-4o-mini"; default_name="openai"; needs_models=true ;;
        7)
            echo ""
            echo -n "  Digite o endpoint: "
            read -r base_url
            default_name="custom"
            needs_models=true
            ;;
        8) base_url="https://integrate.api.nvidia.com/v1"; default_model="nvidia/llama-3.1-nemotron-70b-instruct"; default_name="nvidia"; needs_models=true ;;
        *) show_menu; return ;;
    esac

    echo ""
    echo -n "  Nome para este provider [$default_name]: "
    read -r provider_name
    [ -z "$provider_name" ] && provider_name="$default_name"
    provider_name=$(printf "%s" "$provider_name" | sed 's/[\\\/:*?"<>|]/-/g; s/^[[:space:]]*//; s/[[:space:]]*$//')
    [ -z "$provider_name" ] && provider_name="$default_name"

    echo ""
    echo -n "  Cole sua API Key: "
    read -r api_key
    api_key=$(printf "%s" "$api_key" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

    model_selected=""

    if [ "$needs_models" = true ]; then
        case "$ep_choice" in
            2)
                if ! validate_openrouter_key "$api_key"; then
                    echo ""
                    echo -e "  ${GRAY}[OK] Operacao cancelada.${RESET}"
                    echo ""
                    read -rp "  Pressione Enter para continuar..."
                    show_menu
                    return
                fi
                if select_openrouter_model "$api_key"; then
                    model_selected="$SELECTED_MODEL"
                fi
                ;;
            5) select_gemini_model "$api_key" && model_selected="$SELECTED_MODEL" ;;
            6) select_openai_model "$api_key" && model_selected="$SELECTED_MODEL" ;;
            8)
                [ -z "$api_key" ] && [ -n "$NVIDIA_API_KEY" ] && api_key="$NVIDIA_API_KEY"
                select_nvidia_model "$api_key" && model_selected="$SELECTED_MODEL"
                ;;
        esac

        if [ -z "$model_selected" ]; then
            echo ""
            echo -n "  Digite manualmente o ID do modelo (ENTER para cancelar): "
            read -r model_selected
            model_selected=$(printf "%s" "$model_selected" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
            if [ -z "$model_selected" ]; then
                echo ""
                echo -e "  ${GRAY}[OK] Operacao cancelada.${RESET}"
                echo ""
                read -rp "  Pressione Enter para continuar..."
                show_menu
                return
            fi
        fi
    fi

    model_main="$default_model"
    model_fast="$default_model"
    model_sonnet="$default_model"
    model_opus="$default_model"
    model_haiku="$default_model"

    [ "$needs_models" = true ] && {
        model_main="$model_selected"
        model_fast="$model_selected"
        model_sonnet="$model_selected"
        model_opus="$model_selected"
        model_haiku="$model_selected"
    }

    clear
    echo ""
    echo -e "  ${BOLD}${BLUE}Confirmar Configuracao${RESET}"
    echo -e "$SEP"
    echo -e "  ${GRAY}Provider:${RESET} ${WHITE}$provider_name${RESET}"
    echo -e "  ${GRAY}Endpoint:${RESET} ${WHITE}$base_url${RESET}"
    echo ""
    echo -e "  ${GRAY}Modelos:${RESET}"
    echo -e "    ${GRAY}Principal:${RESET} ${WHITE}$model_main${RESET}"
    echo -e "    ${GRAY}Rapido:${RESET} ${WHITE}$model_fast${RESET}"
    echo -e "    ${GRAY}Sonnet:${RESET} ${WHITE}$model_sonnet${RESET}"
    echo -e "    ${GRAY}Opus:${RESET} ${WHITE}$model_opus${RESET}"
    echo -e "    ${GRAY}Haiku:${RESET} ${WHITE}$model_haiku${RESET}"
    echo -e "$SEP"
    echo -e "  ${GREEN}[ENTER]${RESET} Confirmar e salvar"
    echo -e "  ${RED}[n]${RESET} Cancelar"
    echo ""
    echo -n "  Escolha: "
    read -r confirm

    [[ "$confirm" =~ ^[Nn]$ ]] && show_menu && return

    out_file="$CONFIG_DIR/settings-$provider_name.json"
    tmp_out_file="${out_file}.tmp.$$"

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

    clear
    echo ""
    echo -e "  ${GREEN}${BOLD}Provider salvo!${RESET}"
    echo ""
    echo -e "  ${CYAN}Provider:${RESET} ${WHITE}$provider_name${RESET}"
    echo ""
    echo -n "  Ativar agora? (s/n): "
    read -r ativar
    if [[ "$ativar" =~ ^[Ss]$ ]]; then
        cp "$out_file" "$SETTINGS"
        echo ""
        echo -e "  ${GREEN}${BOLD}Provider ativado!${RESET}"
    fi

    echo ""
    read -rp "  Pressione Enter para continuar... " tmp
    show_menu
}

# Validacao OpenRouter
validate_openrouter_key() {
    response_file=$(mktemp)
    http_code=$(curl -s -m 20 -w "%{http_code}" "https://openrouter.ai/api/v1/key" \
        -H "Authorization: Bearer $1" -o "$response_file" 2>/dev/null)
    response=$(cat "$response_file" 2>/dev/null)
    rm -f "$response_file"

    [ "$http_code" = "200" ] && return 0

    clear
    echo ""
    echo -e "  ${RED}${BOLD}Erro${RESET}"
    echo -e "  ${RED}Chave OpenRouter invalida ou sem acesso.${RESET}"
    echo ""
    return 1
}

# Selecao de modelos
select_openrouter_model() {
    SELECTED_MODEL=""
    clear
    echo ""
    echo -e "  ${BOLD}${BLUE}Selecionar Modelo - OpenRouter${RESET}"
    echo -e "$SEP"
    echo -e "  ${GRAY}Buscando modelos...${RESET}"

    response_file=$(mktemp)
    http_code=$(curl -s -m 30 -w "%{http_code}" "https://openrouter.ai/api/v1/models" \
        -H "Authorization: Bearer $1" -o "$response_file" 2>/dev/null)
    response=$(cat "$response_file" 2>/dev/null)
    rm -f "$response_file"

    [ -z "$response" ] && {
        echo -e "  ${RED}Falha ao buscar modelos.${RESET}"
        return 1
    }

    command -v jq >/dev/null 2>&1 || {
        echo -e "  ${RED}jq necessario.${RESET}"
        return 1
    }

    [ "$http_code" != "200" ] && {
        error=$(echo "$response" | jq -r '.error.message // .error // empty' 2>/dev/null)
        echo -e "  ${RED}${error:-HTTP $http_code}${RESET}"
        return 1
    }

    tmp_file=$(mktemp)
    echo "$response" | jq -r '.data[] | "\(.id)|\(.name // .id)"' 2>/dev/null > "$tmp_file"

    [ ! -s "$tmp_file" ] && {
        echo -e "  ${YELLOW}Nenhum modelo encontrado.${RESET}"
        rm -f "$tmp_file"
        return 1
    }

    total_models=$(wc -l < "$tmp_file")
    echo -e "  ${GRAY}Encontrados ${total_models} modelos${RESET}"
    echo -e "  ${YELLOW}Aviso: modelos free podem retornar 429.${RESET}"
    echo ""

    filter="" page=0 page_size=15 filtered_file=$(mktemp)

    while true; do
        > "$filtered_file"
        while IFS='|' read -r model_id model_name; do
            if [ -z "$filter" ] || [[ "$model_id" == *"$filter"* ]] || [[ "$model_name" == *"$filter"* ]]; then
                printf "%s\n" "$model_id|$model_name" >> "$filtered_file"
            fi
        done < "$tmp_file"

        total_filtered=$(wc -l < "$filtered_file")
        total_pages=$(( (total_filtered + page_size - 1) / page_size ))
        [ "$total_pages" -eq 0 ] && total_pages=1

        clear
        echo ""
        echo -e "  ${BOLD}${BLUE}Selecionar Modelo - OpenRouter${RESET}"
        echo -e "$SEP"
        [ -n "$filter" ] && echo -e "  ${CYAN}Filtro:${RESET} \"$filter\" ($total_filtered resultados)" || echo -e "  ${GRAY}Todos os modelos ($total_filtered)${RESET}"
        echo -e "  ${GRAY}Pagina $((page + 1)) de ${total_pages}${RESET}"
        echo -e "$SEP"

        start=$((page * page_size + 1))
        end=$((start + page_size - 1))
        [ "$end" -gt "$total_filtered" ] && end=$total_filtered

        count=0
        while IFS='|' read -r model_id model_name; do
            count=$((count + 1))
            [ "$count" -ge "$start" ] && [ "$count" -le "$end" ] && echo -e "  ${CYAN}[$count]${RESET} ${WHITE}$model_name${RESET}"
        done < "$filtered_file"

        echo -e "$SEP"
        echo -e "  ${GRAY}[p] Proxima  [a] Anterior  [n] Limpar  [0] Sair${RESET}"
        echo ""
        echo -n "  Escolha ou digite para filtrar: "
        read -r choice || { rm -f "$tmp_file" "$filtered_file"; return 1; }

        case "$choice" in
            0) rm -f "$tmp_file" "$filtered_file"; return 1 ;;
            p|P) [ "$page" -lt $((total_pages - 1)) ] && page=$((page + 1)) ;;
            a|A) [ "$page" -gt 0 ] && page=$((page - 1)) ;;
            n|N) filter=""; page=0 ;;
            *)
                if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "$total_filtered" ]; then
                    selected=$(sed -n "${choice}p" "$filtered_file")
                    SELECTED_MODEL=$(echo "$selected" | cut -d'|' -f1)
                    rm -f "$tmp_file" "$filtered_file"
                    return 0
                fi
                filter="$choice"; page=0
                ;;
        esac
    done
}

select_gemini_model() {
    SELECTED_MODEL=""
    clear
    echo ""
    echo -e "  ${BOLD}${BLUE}Selecionar Modelo - Google AI${RESET}"
    echo -e "$SEP"
    echo -e "  ${GRAY}Buscando modelos...${RESET}"

    response_file=$(mktemp)
    http_code=$(curl -s -m 30 -w "%{http_code}" "https://generativelanguage.googleapis.com/v1beta/models" \
        -H "X-goog-api-key: $1" -o "$response_file" 2>/dev/null)
    response=$(cat "$response_file" 2>/dev/null)
    rm -f "$response_file"

    [ -z "$response" ] && { echo -e "  ${RED}Falha ao buscar modelos.${RESET}"; return 1; }
    command -v jq >/dev/null 2>&1 || { echo -e "  ${RED}jq necessario.${RESET}"; return 1; }
    [ "$http_code" != "200" ] && { echo -e "  ${RED}HTTP $http_code${RESET}"; return 1; }

    tmp_file=$(mktemp)
    echo "$response" | jq -r '.models[] | "\(.name|sub("^models/";""))|\(.displayName // .name)"' 2>/dev/null > "$tmp_file"
    [ ! -s "$tmp_file" ] && { echo -e "  ${YELLOW}Nenhum modelo encontrado.${RESET}"; rm -f "$tmp_file"; return 1; }

    total_models=$(wc -l < "$tmp_file")
    echo -e "  ${GRAY}Encontrados ${total_models} modelos${RESET}"
    echo ""

    filter="" page=0 page_size=10 filtered_file=$(mktemp)

    while true; do
        > "$filtered_file"
        while IFS='|' read -r model_name model_display; do
            if [ -z "$filter" ] || [[ "$model_name" == *"$filter"* ]] || [[ "$model_display" == *"$filter"* ]]; then
                printf "%s\n" "$model_name|$model_display" >> "$filtered_file"
            fi
        done < "$tmp_file"

        total_filtered=$(wc -l < "$filtered_file")
        total_pages=$(( (total_filtered + page_size - 1) / page_size ))
        [ "$total_pages" -eq 0 ] && total_pages=1

        clear
        echo ""
        echo -e "  ${BOLD}${BLUE}Selecionar Modelo - Google AI${RESET}"
        echo -e "$SEP"
        [ -n "$filter" ] && echo -e "  ${CYAN}Filtro:${RESET} \"$filter\" ($total_filtered resultados)" || echo -e "  ${GRAY}Todos os modelos ($total_filtered)${RESET}"
        echo -e "  ${GRAY}Pagina $((page + 1)) de ${total_pages}${RESET}"
        echo -e "$SEP"

        start=$((page * page_size + 1))
        end=$((start + page_size - 1))
        [ "$end" -gt "$total_filtered" ] && end=$total_filtered

        count=0
        while IFS='|' read -r model_name model_display; do
            count=$((count + 1))
            [ "$count" -ge "$start" ] && [ "$count" -le "$end" ] && echo -e "  ${CYAN}[$count]${RESET} ${WHITE}$model_display${RESET}"
        done < "$filtered_file"

        echo -e "$SEP"
        echo -e "  ${GRAY}[p] Proxima  [a] Anterior  [n] Limpar  [0] Sair${RESET}"
        echo ""
        echo -n "  Escolha ou digite para filtrar: "
        read -r choice || { rm -f "$tmp_file" "$filtered_file"; return 1; }

        case "$choice" in
            0) rm -f "$tmp_file" "$filtered_file"; return 1 ;;
            p|P) [ "$page" -lt $((total_pages - 1)) ] && page=$((page + 1)) ;;
            a|A) [ "$page" -gt 0 ] && page=$((page - 1)) ;;
            n|N) filter=""; page=0 ;;
            *)
                if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "$total_filtered" ]; then
                    selected=$(sed -n "${choice}p" "$filtered_file")
                    SELECTED_MODEL=$(echo "$selected" | cut -d'|' -f1 | sed 's/^models\///')
                    rm -f "$tmp_file" "$filtered_file"
                    return 0
                fi
                filter="$choice"; page=0
                ;;
        esac
    done
}

select_openai_model() {
    SELECTED_MODEL=""
    clear
    echo ""
    echo -e "  ${BOLD}${BLUE}Selecionar Modelo - OpenAI${RESET}"
    echo -e "$SEP"
    echo -e "  ${GRAY}Buscando modelos...${RESET}"

    response_file=$(mktemp)
    http_code=$(curl -s -m 30 -w "%{http_code}" "https://api.openai.com/v1/models" \
        -H "Authorization: Bearer $1" -o "$response_file" 2>/dev/null)
    response=$(cat "$response_file" 2>/dev/null)
    rm -f "$response_file"

    [ -z "$response" ] && { echo -e "  ${RED}Falha ao buscar modelos.${RESET}"; return 1; }
    command -v jq >/dev/null 2>&1 || { echo -e "  ${RED}jq necessario.${RESET}"; return 1; }
    [ "$http_code" != "200" ] && { echo -e "  ${RED}HTTP $http_code${RESET}"; return 1; }

    tmp_file=$(mktemp)
    echo "$response" | jq -r '.data[] | "\(.id)"' 2>/dev/null > "$tmp_file"
    [ ! -s "$tmp_file" ] && { echo -e "  ${YELLOW}Nenhum modelo encontrado.${RESET}"; rm -f "$tmp_file"; return 1; }

    total_models=$(wc -l < "$tmp_file")
    echo -e "  ${GRAY}Encontrados ${total_models} modelos${RESET}"
    echo ""

    filter="" page=0 page_size=10 filtered_file=$(mktemp)

    while true; do
        > "$filtered_file"
        while IFS= read -r model_id; do
            if [ -z "$filter" ] || [[ "$model_id" == *"$filter"* ]]; then
                printf "%s\n" "$model_id" >> "$filtered_file"
            fi
        done < "$tmp_file"

        total_filtered=$(wc -l < "$filtered_file")
        total_pages=$(( (total_filtered + page_size - 1) / page_size ))
        [ "$total_pages" -eq 0 ] && total_pages=1

        clear
        echo ""
        echo -e "  ${BOLD}${BLUE}Selecionar Modelo - OpenAI${RESET}"
        echo -e "$SEP"
        [ -n "$filter" ] && echo -e "  ${CYAN}Filtro:${RESET} \"$filter\" ($total_filtered resultados)" || echo -e "  ${GRAY}Todos os modelos ($total_filtered)${RESET}"
        echo -e "  ${GRAY}Pagina $((page + 1)) de ${total_pages}${RESET}"
        echo -e "$SEP"

        start=$((page * page_size + 1))
        end=$((start + page_size - 1))
        [ "$end" -gt "$total_filtered" ] && end=$total_filtered

        count=0
        while IFS= read -r model_id; do
            count=$((count + 1))
            [ "$count" -ge "$start" ] && [ "$count" -le "$end" ] && echo -e "  ${CYAN}[$count]${RESET} ${WHITE}$model_id${RESET}"
        done < "$filtered_file"

        echo -e "$SEP"
        echo -e "  ${GRAY}[p] Proxima  [a] Anterior  [n] Limpar  [0] Sair${RESET}"
        echo ""
        echo -n "  Escolha ou digite para filtrar: "
        read -r choice || { rm -f "$tmp_file" "$filtered_file"; return 1; }

        case "$choice" in
            0) rm -f "$tmp_file" "$filtered_file"; return 1 ;;
            p|P) [ "$page" -lt $((total_pages - 1)) ] && page=$((page + 1)) ;;
            a|A) [ "$page" -gt 0 ] && page=$((page - 1)) ;;
            n|N) filter=""; page=0 ;;
            *)
                if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "$total_filtered" ]; then
                    SELECTED_MODEL=$(sed -n "${choice}p" "$filtered_file")
                    rm -f "$tmp_file" "$filtered_file"
                    return 0
                fi
                filter="$choice"; page=0
                ;;
        esac
    done
}

select_nvidia_model() {
    SELECTED_MODEL=""
    clear
    echo ""
    echo -e "  ${BOLD}${BLUE}Selecionar Modelo - NVIDIA NGC${RESET}"
    echo -e "$SEP"
    echo -e "  ${GRAY}Buscando modelos...${RESET}"

    response_file=$(mktemp)
    http_code=$(curl -s -m 30 -w "%{http_code}" "https://integrate.api.nvidia.com/v1/models" \
        -H "Authorization: Bearer $1" -o "$response_file" 2>/dev/null)
    response=$(cat "$response_file" 2>/dev/null)
    rm -f "$response_file"

    [ -z "$response" ] && { echo -e "  ${RED}Falha ao buscar modelos.${RESET}"; return 1; }
    command -v jq >/dev/null 2>&1 || { echo -e "  ${RED}jq necessario.${RESET}"; return 1; }
    [ "$http_code" != "200" ] && { echo -e "  ${RED}HTTP $http_code${RESET}"; return 1; }

    tmp_file=$(mktemp)
    echo "$response" | jq -r '.data[] | "\(.id)"' 2>/dev/null > "$tmp_file"
    [ ! -s "$tmp_file" ] && { echo -e "  ${YELLOW}Nenhum modelo encontrado.${RESET}"; rm -f "$tmp_file"; return 1; }

    total_models=$(wc -l < "$tmp_file")
    echo -e "  ${GRAY}Encontrados ${total_models} modelos${RESET}"
    echo ""

    filter="" page=0 page_size=15 filtered_file=$(mktemp)

    while true; do
        > "$filtered_file"
        while IFS= read -r model_id; do
            if [ -z "$filter" ] || [[ "$model_id" == *"$filter"* ]]; then
                printf "%s\n" "$model_id" >> "$filtered_file"
            fi
        done < "$tmp_file"

        total_filtered=$(wc -l < "$filtered_file")
        total_pages=$(( (total_filtered + page_size - 1) / page_size ))
        [ "$total_pages" -eq 0 ] && total_pages=1

        clear
        echo ""
        echo -e "  ${BOLD}${BLUE}Selecionar Modelo - NVIDIA NGC${RESET}"
        echo -e "$SEP"
        [ -n "$filter" ] && echo -e "  ${CYAN}Filtro:${RESET} \"$filter\" ($total_filtered resultados)" || echo -e "  ${GRAY}Todos os modelos ($total_filtered)${RESET}"
        echo -e "  ${GRAY}Pagina $((page + 1)) de ${total_pages}${RESET}"
        echo -e "$SEP"

        start=$((page * page_size + 1))
        end=$((start + page_size - 1))
        [ "$end" -gt "$total_filtered" ] && end=$total_filtered

        count=0
        while IFS= read -r model_id; do
            count=$((count + 1))
            [ "$count" -ge "$start" ] && [ "$count" -le "$end" ] && echo -e "  ${CYAN}[$count]${RESET} ${WHITE}$model_id${RESET}"
        done < "$filtered_file"

        echo -e "$SEP"
        echo -e "  ${GRAY}[p] Proxima  [a] Anterior  [n] Limpar  [0] Sair${RESET}"
        echo ""
        echo -n "  Escolha ou digite para filtrar: "
        read -r choice || { rm -f "$tmp_file" "$filtered_file"; return 1; }

        case "$choice" in
            0) rm -f "$tmp_file" "$filtered_file"; return 1 ;;
            p|P) [ "$page" -lt $((total_pages - 1)) ] && page=$((page + 1)) ;;
            a|A) [ "$page" -gt 0 ] && page=$((page - 1)) ;;
            n|N) filter=""; page=0 ;;
            *)
                if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "$total_filtered" ]; then
                    SELECTED_MODEL=$(sed -n "${choice}p" "$filtered_file")
                    rm -f "$tmp_file" "$filtered_file"
                    return 0
                fi
                filter="$choice"; page=0
                ;;
        esac
    done
}

remove_provider() {
    clear
    echo ""
    echo -e "  ${BOLD}${BLUE}Remover Provider${RESET}"
    echo -e "$SEP"
    echo -e "  ${GRAY}Qual provider deseja remover?${RESET}"
    echo ""

    count=0 files=()
    for f in "$CONFIG_DIR"/settings-*.json; do
        [ -f "$f" ] || continue
        base=$(basename "$f" .json)
        [ "$base" = "settings-before-native-anthropic" ] && continue
        count=$((count + 1))
        name="${base#settings-}"
        files+=("$name")
        echo -e "    ${CYAN}[$count]${RESET} ${WHITE}$name${RESET}"
    done

    echo ""
    echo -e "  ${GRAY}[0]${RESET} Cancelar"
    echo ""
    echo -n "  Escolha: "
    read -r rdel

    [ "$rdel" = "0" ] || [ -z "$rdel" ] && show_menu && return

    if [[ "$rdel" =~ ^[0-9]+$ ]] && [ "$rdel" -ge 1 ] && [ "$rdel" -le "$count" ]; then
        selected="${files[$((rdel - 1))]}"
        echo ""
        echo -e "  ${YELLOW}Remover ${WHITE}$selected${YELLOW}?${RESET}"
        echo -e "  ${GRAY}[ENTER]${RESET} ${GREEN}Confirmar${RESET}  ${GRAY}[n]${RESET} Cancelar"
        echo ""
        echo -n "  Escolha: "
        read -r confirm
        [[ "$confirm" =~ ^[Nn]$ ]] && show_menu && return
        rm "$CONFIG_DIR/settings-$selected.json"
        echo ""
        echo -e "  ${GREEN}Provider removido!${RESET}"
    fi

    echo ""
    read -rp "  Pressione Enter para continuar... " tmp
    show_menu
}

change_openrouter_model() {
    clear
    echo ""

    [ ! -f "$SETTINGS" ] && {
        echo -e "  ${RED}settings.json nao encontrado.${RESET}"
        read -rp "  Pressione Enter para continuar... " tmp
        show_menu
        return
    }

    command -v jq >/dev/null 2>&1 || {
        echo -e "  ${RED}jq nao instalado.${RESET}"
        read -rp "  Pressione Enter para continuar... " tmp
        show_menu
        return
    }

    base_url=$(jq -r '.env.ANTHROPIC_BASE_URL // empty' "$SETTINGS" 2>/dev/null)
    api_key=$(jq -r '.env.ANTHROPIC_AUTH_TOKEN // empty' "$SETTINGS" 2>/dev/null)
    current_model=$(jq -r '.env.ANTHROPIC_MODEL // empty' "$SETTINGS" 2>/dev/null)

    [[ "$base_url" != *openrouter.ai* ]] && {
        echo -e "  ${RED}O provider ativo nao e OpenRouter.${RESET}"
        read -rp "  Pressione Enter para continuar... " tmp
        show_menu
        return
    }

    [ -z "$api_key" ] && {
        echo -e "  ${RED}API key nao encontrada.${RESET}"
        read -rp "  Pressione Enter para continuar... " tmp
        show_menu
        return
    }

    echo -e "  ${GRAY}Modelo atual:${RESET} ${WHITE}${current_model:-nao definido}${RESET}"
    echo -e "  ${GRAY}Buscando modelos...${RESET}"
    echo ""

    model_selected=""
    select_openrouter_model "$api_key" && model_selected="$SELECTED_MODEL"

    [ -z "$model_selected" ] && {
        echo -e "  ${GRAY}Operacao cancelada.${RESET}"
        read -rp "  Pressione Enter para continuar... " tmp
        show_menu
        return
    }

    clear
    echo ""
    echo -e "  ${BOLD}${BLUE}Confirmar Troca de Modelo${RESET}"
    echo -e "$SEP"
    echo -e "  ${GRAY}Modelo atual:${RESET} ${WHITE}${current_model:-nao definido}${RESET}"
    echo -e "  ${CYAN}Novo modelo:${RESET} ${WHITE}$model_selected${RESET}"
    echo -e "$SEP"
    echo -e "  ${GREEN}[ENTER]${RESET} Confirmar  ${RED}[n]${RESET} Cancelar"
    echo ""
    echo -n "  Escolha: "
    read -r confirm

    [[ "$confirm" =~ ^[Nn]$ ]] && show_menu && return

    tmp_settings="${SETTINGS}.tmp.$$"
    jq --arg model "$model_selected" '
        .env.ANTHROPIC_MODEL = $model |
        .env.ANTHROPIC_SMALL_FAST_MODEL = $model |
        .env.ANTHROPIC_DEFAULT_SONNET_MODEL = $model |
        .env.ANTHROPIC_DEFAULT_OPUS_MODEL = $model |
        .env.ANTHROPIC_DEFAULT_HAIKU_MODEL = $model
    ' "$SETTINGS" > "$tmp_settings" || {
        rm -f "$tmp_settings"
        echo -e "  ${RED}Falha ao atualizar settings.json.${RESET}"
        read -rp "  Pressione Enter para continuar... " tmp
        show_menu
        return
    }
    mv "$tmp_settings" "$SETTINGS"

    for f in "$CONFIG_DIR"/settings-*.json; do
        [ -f "$f" ] || continue
        [ "$(basename "$f" .json)" = "settings-before-native-anthropic" ] && continue
        cmp -s "$f" "$SETTINGS" && cp "$SETTINGS" "$f" && break
    done

    echo ""
    echo -e "  ${GREEN}${BOLD}Modelo atualizado!${RESET}"
    echo -e "  ${YELLOW}Reinicie o Claude Code para aplicar!${RESET}"

    echo ""
    read -rp "  Pressione Enter para continuar... " tmp
    show_menu
}

view_current() {
    clear
    echo ""
    echo -e "  ${BOLD}${BLUE}Provider Ativo - settings.json${RESET}"
    echo -e "$SEP"

    if [ -f "$SETTINGS" ]; then
        echo -e "  ${GREEN}[v] ativo${RESET}"
        echo ""
        if command -v jq >/dev/null 2>&1; then
            jq '.env.ANTHROPIC_AUTH_TOKEN |= (if . then ((.[0:4] // "") + "****************************") else . end) |
                .env.ANTHROPIC_API_KEY |= (if . then ((.[0:4] // "") + "****************************") else . end)
            ' "$SETTINGS" 2>/dev/null
        else
            sed -E \
                's/"ANTHROPIC_AUTH_TOKEN":[[:space:]]*"([^"]{0,4})[^"]*"/"ANTHROPIC_AUTH_TOKEN": "\1****************************"/g
                s/"ANTHROPIC_API_KEY":[[:space:]]*"([^"]{0,4})[^"]*"/"ANTHROPIC_API_KEY": "\1****************************"/g' \
                "$SETTINGS"
        fi
        echo ""
        echo -e "  ${YELLOW}API keys ocultas por seguranca.${RESET}"
    else
        echo -e "  ${RED}settings.json nao encontrado!${RESET}"
    fi

    echo ""
    read -rp "  Pressione Enter para continuar... " tmp
    show_menu
}

show_goodbye() {
    clear
    echo ""
    echo -e "  ${BOLD}${BLUE}Obrigado por usar!${RESET}"
    echo -e "  ${GRAY}Claude Code - Provider Manager${RESET}"
    echo ""
    echo -e "  ${CYAN}[T]/ Hasta la vista!${RESET}"
    echo ""
    exit 0
}

# Verifica se a pasta .claude existe
[ ! -d "$CONFIG_DIR" ] && mkdir -p "$CONFIG_DIR"

show_menu