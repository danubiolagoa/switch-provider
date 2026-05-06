@echo off
setlocal enabledelayedexpansion

set "CONFIG_DIR=%USERPROFILE%\.claude"
set "SETTINGS=%CONFIG_DIR%\settings.json"

if not exist "%CONFIG_DIR%" mkdir "%CONFIG_DIR%"
call :NORMALIZE_PROVIDER_FILES
for /f %%e in ('echo prompt $E ^| cmd') do set "ESC=%%e"

REM ─────────────────────────────────────────────────────────
REM Design System TUI - Cores
REM ─────────────────────────────────────────────────────────
if defined ESC (
    set "RED=!ESC![31m"
    set "GREEN=!ESC![32m"
    set "YELLOW=!ESC![33m"
    set "BLUE=!ESC![34m"
    set "MAGENTA=!ESC![35m"
    set "CYAN=!ESC![36m"
    set "WHITE=!ESC![37m"
    set "GRAY=!ESC![90m"
    set "BOLD=!ESC![1m"
    set "RESET=!ESC![0m"
) else (
    set "RED="
    set "GREEN="
    set "YELLOW="
    set "BLUE="
    set "CYAN="
    set "WHITE="
    set "GRAY="
    set "BOLD="
    set "RESET="
)

set "SEP=  !GRAY!------------------------------------------------!RESET!"

:MENU
cls
echo.
echo   !BOLD!!BLUE!Claude Code - Provider Manager!RESET!
echo !SEP!

set COUNT=0
set "CURRENT_LABEL="
set "CURRENT_PROVIDER="
set "CURRENT_MODEL="
for %%F in ("%CONFIG_DIR%\settings-*.json") do (
    set "LABEL=%%~nF"
    if /i not "!LABEL!"=="settings-before-native-anthropic" (
        set /a COUNT+=1
        set "FILE_!COUNT!=%%~nF"
        set "LABEL=!LABEL:settings-=!"
        set "LABEL_!COUNT!=!LABEL!"
        if exist "%SETTINGS%" (
            fc /b "%%F" "%SETTINGS%" >nul 2>&1
            if !errorlevel! EQU 0 set "CURRENT_LABEL=!LABEL!"
        )
    )
)

if defined CURRENT_LABEL set "CURRENT_PROVIDER=!CURRENT_LABEL!"
if exist "%SETTINGS%" (
    if not defined CURRENT_PROVIDER (
        findstr /C:"\"ANTHROPIC_BASE_URL\"" "%SETTINGS%" >nul 2>&1
        if not errorlevel 1 (
            set "CURRENT_PROVIDER=custom (base_url)"
        ) else (
            findstr /C:"\"ANTHROPIC_API_KEY\"" "%SETTINGS%" >nul 2>&1
            if not errorlevel 1 (
                set "CURRENT_PROVIDER=anthropic (api key)"
            ) else (
                set "CURRENT_PROVIDER=claude padrao (anthropic login)"
            )
        )
    )
    for /f "usebackq delims=" %%M in (`powershell -NoProfile -Command "$j = Get-Content -Raw -LiteralPath '%SETTINGS%' | ConvertFrom-Json; if ($j.env.ANTHROPIC_MODEL) { [string]$j.env.ANTHROPIC_MODEL }"`) do set "CURRENT_MODEL=%%M"
) else (
    set "CURRENT_PROVIDER=nenhum"
)

echo   !GRAY!provider:!RESET! !WHITE!!CURRENT_PROVIDER!!RESET!
echo.
echo   !GRAY!Providers:!RESET!
for /L %%I in (1,1,%COUNT%) do (
    call :PRINT_PROVIDER %%I "!LABEL_%%I!"
)

echo.
echo !SEP!
echo   !GRAY![a]!RESET! Adicionar novo provider
echo   !GRAY![r]!RESET! Remover provider
echo   !GRAY![n]!RESET! Claude padrao (Anthropic login)
echo   !GRAY![v]!RESET! Ver provider atual
echo !SEP!
echo   !GRAY![0]!RESET! !WHITE!Sair!RESET!
echo.
if defined CURRENT_MODEL (
    echo   !GRAY!Modelo:!RESET! !CYAN!!CURRENT_MODEL!!RESET!
)
echo.
set /p CHOICE="  Escolha: "

if "%CHOICE%"=="0" goto FIM
if "%CHOICE%"=="a" goto NOVO
if "%CHOICE%"=="r" goto REMOVER
if "%CHOICE%"=="n" goto USE_NATIVE_ANTHROPIC
if "%CHOICE%"=="v" goto STATUS

for /L %%I in (1,1,%COUNT%) do (
    if "%CHOICE%"=="%%I" (
        call :ATIVAR "!FILE_%%I!" "!LABEL_%%I!"
        goto MENU
    )
)
goto MENU

:PRINT_PROVIDER
set "IDX=%~1"
set "LBL=%~2"
if defined CURRENT_LABEL if /i "!LBL!"=="!CURRENT_LABEL!" (
    echo     !CYAN![!IDX!]!RESET! !WHITE!!LBL!!RESET! !GREEN![ativo]!RESET!
    goto :EOF
)
echo     !CYAN![!IDX!]!RESET! !WHITE!!LBL!!RESET!
goto :EOF

:ATIVAR
cls
echo.
set "SOURCE_FILE=%CONFIG_DIR%\%~1.json"
powershell -NoProfile -Command "$ErrorActionPreference='Stop'; Get-Content -Raw -LiteralPath $env:SOURCE_FILE | ConvertFrom-Json | Out-Null" >nul 2>&1
if errorlevel 1 (
    echo.
    echo   !RED![ERRO]!RESET! Provider invalido ou corrompido.
    echo   Arquivo: %~1.json
    echo.
    pause
    goto :EOF
)
set "TMP_SETTINGS=%SETTINGS%.tmp"
copy /Y "%CONFIG_DIR%\%~1.json" "!TMP_SETTINGS!" >nul
move /Y "!TMP_SETTINGS!" "%SETTINGS%" >nul
echo.
echo   !GREEN!Provider ativado:!RESET! !BOLD!!WHITE!!%~2!!RESET!
echo.
echo   !YELLOW![AVISO] Reinicie o Claude Code!RESET!
echo.
pause
goto MENU

:USE_NATIVE_ANTHROPIC
cls
echo.
if exist "%SETTINGS%" copy /Y "%SETTINGS%" "%CONFIG_DIR%\settings-before-native-anthropic.json" >nul
set "TMP_NATIVE_SETTINGS=%SETTINGS%.tmp"
(
    echo {
    echo   "env": {
    echo     "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC": "1"
    echo   },
    echo   "autoUpdatesChannel": "latest"
    echo }
) > "!TMP_NATIVE_SETTINGS!"
move /Y "!TMP_NATIVE_SETTINGS!" "%SETTINGS%" >nul
echo.
echo   !GREEN!Anthropic Nativo Ativado!RESET!
echo.
echo   !GRAY!Proximos passos:!RESET!
echo.
echo     1) !GRAY!Reinicie o Claude Code!RESET!
echo     2) !GRAY!Rode /login ou claude login!RESET!
echo     3) !GRAY!Selecione Anthropic!RESET!
echo.
pause
goto MENU

:NOVO
cls
echo.
echo   !BOLD!!BLUE!Adicionar Novo Provider!RESET!
echo.
echo   !GRAY!Selecione o endpoint:!RESET!
echo.
echo     !CYAN![1]!RESET! !WHITE!MiniMax     !RESET! !GRAY!api.minimax.io/anthropic!RESET!
echo     !CYAN![2]!RESET! !WHITE!OpenRouter  !RESET! !GRAY!openrouter.ai/api!RESET!
echo     !CYAN![3]!RESET! !WHITE!Anthropic   !RESET! !GRAY!(API key oficial)!RESET!
echo     !CYAN![4]!RESET! !WHITE!Z.AI / GLM  !RESET! !GRAY!api.z.ai/api/anthropic!RESET!
echo     !CYAN![5]!RESET! !WHITE!Google AI   !RESET! !GRAY!generativelanguage.googleapis!RESET!
echo     !CYAN![6]!RESET! !WHITE!OpenAI      !RESET! !GRAY!api.openai.com/v1!RESET!
echo     !CYAN![7]!RESET! !WHITE!Outro       !RESET! !GRAY!(digitar manualmente)!RESET!
echo     !CYAN![8]!RESET! !WHITE!NVIDIA     !RESET! !GRAY!integrate.api.nvidia.com!RESET!
echo.
set /p EP="  Endpoint: "

set "BASE_URL="
set "DEF_MODEL="
set "DEF_NAME=custom"
set "NATIVE=0"
set "NEEDS_MODELS=0"

if "%EP%"=="1" (
    set "BASE_URL=https://api.minimax.io/anthropic"
    set "DEF_MODEL=MiniMax-M2.7"
    set "DEF_NAME=minimax"
)
if "%EP%"=="2" (
    set "BASE_URL=https://openrouter.ai/api"
    set "DEF_MODEL="
    set "DEF_NAME=openrouter"
    set "NEEDS_MODELS=1"
)
if "%EP%"=="3" (
    set "NATIVE=1"
    set "DEF_MODEL=claude-sonnet-4-20250514"
    set "DEF_NAME=anthropic"
)
if "%EP%"=="4" (
    set "BASE_URL=https://api.z.ai/api/anthropic"
    set "DEF_MODEL=GLM-4.7"
    set "DEF_NAME=glm"
)
if "%EP%"=="5" (
    set "BASE_URL=https://generativelanguage.googleapis.com"
    set "DEF_MODEL=gemini-2.0-flash"
    set "DEF_NAME=gemini"
    set "NEEDS_MODELS=1"
)
if "%EP%"=="6" (
    set "BASE_URL=https://api.openai.com/v1"
    set "DEF_MODEL=gpt-4o-mini"
    set "DEF_NAME=openai"
    set "NEEDS_MODELS=1"
)
if "%EP%"=="7" (
    echo.
    set /p BASE_URL="  Digite o endpoint: "
    set "NEEDS_MODELS=1"
)
if "%EP%"=="8" (
    set "BASE_URL=https://integrate.api.nvidia.com/v1"
    set "DEF_MODEL=nvidia/llama-3.1-nemotron-70b-instruct"
    set "DEF_NAME=nvidia"
    set "NEEDS_MODELS=1"
)

echo.
set /p PNAME="  Nome do provider [!DEF_NAME!]: "
if "!PNAME!"=="" set "PNAME=!DEF_NAME!"
set "PNAME_FALLBACK=!DEF_NAME!"
if "!PNAME_FALLBACK!"=="" set "PNAME_FALLBACK=custom"
for /f "usebackq delims=" %%A in (`powershell -NoProfile -Command "$n=[string]$env:PNAME; if(-not $n){$n=[string]$env:PNAME_FALLBACK}; $n=$n.Trim(); $n=[regex]::Replace($n,'[^A-Za-z0-9._ -]','-'); $n=$n.Trim(' ','.'); if(-not $n){$n=[string]$env:PNAME_FALLBACK}; if(-not $n){$n='custom'}; [Console]::Write($n)"`) do set "PNAME=%%A"
if "!PNAME!"=="" set "PNAME=!DEF_NAME!"
if "!PNAME!"=="" set "PNAME=custom"

echo.
set /p APIKEY="  Cole sua API Key: "
for /f "tokens=* delims= " %%A in ("!APIKEY!") do set "APIKEY=%%A"
:TRIM_APIKEY_RIGHT
if "!APIKEY:~-1!"==" " (
    set "APIKEY=!APIKEY:~0,-1!"
    goto TRIM_APIKEY_RIGHT
)

set "MODEL_MAIN=!DEF_MODEL!"
set "MODEL_FAST=!DEF_MODEL!"
set "MODEL_SONNET=!DEF_MODEL!"
set "MODEL_OPUS=!DEF_MODEL!"
set "MODEL_HAIKU=!DEF_MODEL!"
set "SELECTED_MODEL="

if "!NEEDS_MODELS!"=="1" (
    if "!EP!"=="2" (
        call :VALIDATE_OPENROUTER_KEY
        if not defined OPENROUTER_KEY_OK (
            echo.
            echo [OK] Operacao cancelada.
            pause
            goto MENU
        )
        call :SELECT_OPENROUTER_MODEL
    ) else if "!EP!"=="5" (
        call :SELECT_GEMINI_MODEL
    ) else if "!EP!"=="6" (
        call :SELECT_OPENAI_MODEL
    ) else if "!EP!"=="8" (
        call :SELECT_NVIDIA_MODEL
    )
)

if defined SELECTED_MODEL (
    set "MODEL_MAIN=!SELECTED_MODEL!"
    set "MODEL_FAST=!SELECTED_MODEL!"
    set "MODEL_SONNET=!SELECTED_MODEL!"
    set "MODEL_OPUS=!SELECTED_MODEL!"
    set "MODEL_HAIKU=!SELECTED_MODEL!"
) else (
    if "!NEEDS_MODELS!"=="1" (
        echo.
        set /p MANUAL_MODEL="  Digite manualmente o ID do modelo (ENTER para cancelar): "
        for /f "tokens=* delims= " %%A in ("!MANUAL_MODEL!") do set "MANUAL_MODEL=%%A"
        :TRIM_MANUAL_MODEL_RIGHT
        if "!MANUAL_MODEL:~-1!"==" " (
            set "MANUAL_MODEL=!MANUAL_MODEL:~0,-1!"
            goto TRIM_MANUAL_MODEL_RIGHT
        )
        if "!MANUAL_MODEL!"=="" (
            echo.
            echo [OK] Operacao cancelada.
            pause
            goto MENU
        )
        set "MODEL_MAIN=!MANUAL_MODEL!"
        set "MODEL_FAST=!MANUAL_MODEL!"
        set "MODEL_SONNET=!MANUAL_MODEL!"
        set "MODEL_OPUS=!MANUAL_MODEL!"
        set "MODEL_HAIKU=!MANUAL_MODEL!"
    )
)

REM Confirmacao
cls
echo.
echo   !BOLD!!BLUE!Confirmar Configuracao!RESET!
echo   !GRAY!------------------------------------------------!RESET!
echo   Provider: !WHITE!!PNAME!!RESET!
echo   Endpoint: !WHITE!!BASE_URL!!RESET!
echo.
echo   !GRAY!Modelos selecionados:!RESET!
echo     Principal:   !CYAN!!MODEL_MAIN!!RESET!
echo     Rapido:      !CYAN!!MODEL_FAST!!RESET!
echo     Sonnet:      !CYAN!!MODEL_SONNET!!RESET!
echo     Opus:        !CYAN!!MODEL_OPUS!!RESET!
echo     Haiku:       !CYAN!!MODEL_HAIKU!!RESET!
echo   !GRAY!------------------------------------------------!RESET!
echo   !GRAY![ENTER]!RESET! Confirmar
echo   !GRAY![n]!RESET! Cancelar
echo.
set /p CONFIRM="  Escolha: "
if /i "!CONFIRM!"=="n" goto MENU

set "OUT=%CONFIG_DIR%\settings-!PNAME!.json"
set "OUT_TMP=!OUT!.tmp"

if exist "!OUT!" (
    echo.
    echo   !YELLOW![AVISO]!RESET! Ja existe um provider com esse nome:
    echo          !PNAME!
    set /p OVERWRITE="  Sobrescrever? (s/n): "
    if /i not "!OVERWRITE!"=="s" goto MENU
)

if "!NATIVE!"=="1" (
    (
        echo {
        echo   "env": {
        echo     "ANTHROPIC_API_KEY": "!APIKEY!",
        echo     "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC": "1"
        echo   },
        echo   "autoUpdatesChannel": "latest"
        echo }
    ) > "!OUT_TMP!"
) else (
    (
        echo {
        echo   "env": {
        echo     "ANTHROPIC_BASE_URL": "!BASE_URL!",
        echo     "ANTHROPIC_AUTH_TOKEN": "!APIKEY!",
        echo     "ANTHROPIC_API_KEY": "",
        echo     "API_TIMEOUT_MS": "3000000",
        echo     "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC": "1",
        echo     "ANTHROPIC_MODEL": "!MODEL_MAIN!",
        echo     "ANTHROPIC_SMALL_FAST_MODEL": "!MODEL_FAST!",
        echo     "ANTHROPIC_DEFAULT_SONNET_MODEL": "!MODEL_SONNET!",
        echo     "ANTHROPIC_DEFAULT_OPUS_MODEL": "!MODEL_OPUS!",
        echo     "ANTHROPIC_DEFAULT_HAIKU_MODEL": "!MODEL_HAIKU!"
        echo   },
        echo   "autoUpdatesChannel": "latest"
        echo }
    ) > "!OUT_TMP!"
)

powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; Get-Content -Raw -LiteralPath $env:OUT_TMP | ConvertFrom-Json | Out-Null" >nul 2>&1
if errorlevel 1 (
    del "!OUT_TMP!" 2>nul
    echo.
    echo   !RED![ERRO]!RESET! Falha ao salvar provider.
    echo   O arquivo gerado ficou invalido.
    echo   Tente novamente com outro nome/modelo.
    echo.
    pause
    goto MENU
)

move /Y "!OUT_TMP!" "!OUT!" >nul

echo.
echo   !GREEN![OK]!RESET! Provider "!PNAME!" salvo!
echo.
set /p ATIVAR_NOW="  Ativar agora? (s/n): "
if /i "!ATIVAR_NOW!"=="s" (
    set "TMP_SETTINGS=%SETTINGS%.tmp"
    copy /Y "!OUT!" "!TMP_SETTINGS!" >nul
    move /Y "!TMP_SETTINGS!" "%SETTINGS%" >nul
    echo.
    echo   !GREEN![OK]!RESET! Provider "!PNAME!" ativado!
    echo   !YELLOW![AVISO] Reinicie o Claude Code!RESET!
)
echo.
pause
goto MENU

:REMOVER
cls
echo.
echo   !BOLD!!BLUE!Remover Provider!RESET!
echo.
set C2=0
for %%F in ("%CONFIG_DIR%\settings-*.json") do (
    set "RL=%%~nF"
    if /i not "!RL!"=="settings-before-native-anthropic" (
        set /a C2+=1
        set "RF_!C2!=%%~nF"
        set "RL=!RL:settings-=!"
        set "RL_!C2!=!RL!"
        echo     !CYAN![!C2!]!RESET! !WHITE!!RL!!RESET!
    )
)
echo.
echo   !GRAY![0]!RESET! Cancelar
echo.
set /p RD="  Escolha: "
if "!RD!"=="0" goto MENU
for /L %%I in (1,1,%C2%) do (
    if "!RD!"=="%%I" (
        set /p CF="  Remover !RL_%%I!? (s/n): "
        if /i "!CF!"=="s" (
            del "%CONFIG_DIR%\!RF_%%I!.json"
            echo   !GREEN![OK]!RESET! Removido.
        )
    )
)
echo.
pause
goto MENU

:STATUS
cls
echo.
echo   !BOLD!!BLUE!Provider Ativo - settings.json!RESET!
echo   !GRAY!------------------------------------------------!RESET!
if not exist "%SETTINGS%" (
    echo   !RED![ERRO]!RESET! settings.json nao encontrado!
    echo   !GRAY!------------------------------------------------!RESET!
    pause
    goto MENU
)
echo   Status: !GREEN![v] ativo!RESET!
echo   !GRAY!------------------------------------------------!RESET!
echo.
for /f "usebackq delims=" %%L in (`powershell -NoProfile -Command "$j = Get-Content -Raw -LiteralPath '%SETTINGS%' | ConvertFrom-Json; if ($j.env.ANTHROPIC_AUTH_TOKEN) { $v = [string]$j.env.ANTHROPIC_AUTH_TOKEN; $j.env.ANTHROPIC_AUTH_TOKEN = $v.Substring(0, [Math]::Min(4, $v.Length)) + '****************************' }; if ($j.env.ANTHROPIC_API_KEY) { $v = [string]$j.env.ANTHROPIC_API_KEY; $j.env.ANTHROPIC_API_KEY = $v.Substring(0, [Math]::Min(4, $v.Length)) + '****************************' }; $j | ConvertTo-Json -Depth 8"`) do echo   %%L
echo.
echo   !YELLOW![AVISO]!RESET! API keys ocultas por seguranca.
echo.
pause
goto MENU

:FIM
cls
echo.
echo   !BOLD!!BLUE!Obrigado por usar!!RESET!
echo   !GRAY!Claude Code - Provider Manager!RESET!
echo.
echo   !CYAN![T] /!RESET! !WHITE!Hasta la vista!!RESET!
echo.
exit /b 0

REM ============================================================
REM Selecao de modelos via API
REM ============================================================

:VALIDATE_OPENROUTER_KEY
set "OPENROUTER_KEY_OK="
set "KEY_CHECK_FILE=%TEMP%\openrouter_key_%RANDOM%.txt"
curl -s -m 20 "https://openrouter.ai/api/v1/key" -H "Authorization: Bearer %APIKEY%" -o "%KEY_CHECK_FILE%" 2>nul
if not exist "%KEY_CHECK_FILE%" goto OR_KEY_INVALID
for %%Z in ("%KEY_CHECK_FILE%") do if %%~zZ LEQ 0 goto OR_KEY_INVALID

set "KEY_ERR_FILE=%TEMP%\openrouter_key_err_%RANDOM%.txt"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\validate-openrouter-key.ps1" "%KEY_CHECK_FILE%" >"%KEY_ERR_FILE%" 2>&1
if not errorlevel 1 (
    set "OPENROUTER_KEY_OK=1"
    del "%KEY_CHECK_FILE%" 2>nul
    del "%KEY_ERR_FILE%" 2>nul
    goto :EOF
)

:OR_KEY_INVALID
set "OR_KEY_ERR="
if exist "%KEY_ERR_FILE%" (
    for /f "usebackq delims=" %%E in ("%KEY_ERR_FILE%") do (
        if not defined OR_KEY_ERR set "OR_KEY_ERR=%%E"
    )
)
echo.
echo   !RED![ERRO]!RESET! Chave OpenRouter invalida ou sem acesso.
if defined OR_KEY_ERR echo   !OR_KEY_ERR!
if not defined OR_KEY_ERR echo   Falha na autenticacao OpenRouter.
del "%KEY_CHECK_FILE%" 2>nul
del "%KEY_ERR_FILE%" 2>nul
goto :EOF

:SELECT_OPENROUTER_MODEL
set "SELECTED_MODEL="
set "FILTER="
set "PAGE=0"
set "PAGE_SIZE=15"
set "FILTERED_FILE=%TEMP%\openrouter_filtered_%RANDOM%.txt"
goto OR_MODEL_PAGE

:OR_MATCH_FILTER
set "OR_MATCH="
if not defined FILTER (
    set "OR_MATCH=1"
    goto :EOF
)
echo !MATCH_LINE! | findstr /I /C:"!FILTER!" >nul
if not errorlevel 1 set "OR_MATCH=1"
goto :EOF

:OR_MODEL_PAGE
REM Aplica filtro
if exist "!FILTERED_FILE!" del /f /q "!FILTERED_FILE!" 2>nul
set /a FILTERED_COUNT=0
for /f "tokens=1,* delims=:" %%A in ('findstr /n "^" "%MODELS_FILE%"') do (
    set "MATCH_LINE=%%B"
    call :OR_MATCH_FILTER
    if defined OR_MATCH (
        echo !MATCH_LINE! >> "!FILTERED_FILE!"
        set /a FILTERED_COUNT+=1
    )
)
if "!FILTERED_COUNT!"=="0" (
    echo   Nenhum modelo corresponde ao filtro.
)

set /a TOTAL_PAGES=(!FILTERED_COUNT! + %PAGE_SIZE% - 1) / %PAGE_SIZE%
if !TOTAL_PAGES! lss 1 set /a TOTAL_PAGES=1

cls
echo.
echo   !BOLD!!BLUE!Selecionar Modelo - OpenRouter!RESET!
echo   !GRAY!------------------------------------------------!RESET!
if defined FILTER (
    echo   Filtro: !CYAN!!FILTER!!RESET! (!FILTERED_COUNT! resultados)
) else (
    echo   Todos os modelos (!FILTERED_COUNT!)
)
echo   Pagina !PAGE! de !TOTAL_PAGES!
echo   !GRAY!------------------------------------------------!RESET!

set /a START=PAGE*PAGE_SIZE+1
set /a END=START+PAGE_SIZE-1
set /a DISP_COUNT=0
for /f "tokens=1,* delims=:" %%A in ('findstr /n "^" "!FILTERED_FILE!"') do (
    if %%A geq !START! (
        if %%A leq !END! (
            echo     !CYAN![%%A]!RESET! %%B
            set /a DISP_COUNT+=1
        )
    )
)

echo   !GRAY!------------------------------------------------!RESET!
echo   !GRAY![p]!RESET! Proxima pagina  !GRAY![a]!RESET! Pagina anterior
if defined FILTER (
    echo   !GRAY![n]!RESET! Limpar filtro
)
echo   !GRAY![0]!RESET! Cancelar
echo   !GRAY!------------------------------------------------!RESET!
echo.
set /p CHOICE="  Escolha ou digite para filtrar: "

if "!CHOICE!"=="0" (
    del "%RESPONSE_FILE%" 2>nul
    del "%MODELS_FILE%" 2>nul
    if exist "!FILTERED_FILE!" del /f /q "!FILTERED_FILE!" 2>nul
    goto :EOF
)
if /i "!CHOICE!"=="p" (
    if !END! lss !FILTERED_COUNT! set /a PAGE+=1
    goto OR_MODEL_PAGE
)
if /i "!CHOICE!"=="a" (
    if !PAGE! gtr 0 set /a PAGE-=1
    goto OR_MODEL_PAGE
)
if /i "!CHOICE!"=="n" (
    set "FILTER="
    set "PAGE=0"
    goto OR_MODEL_PAGE
)

echo(!CHOICE!| findstr /R "^[0-9][0-9]*$" >nul
if not errorlevel 1 (
    set /a CHOICE_NUM=!CHOICE!
    if !CHOICE_NUM! geq 1 if !CHOICE_NUM! leq !FILTERED_COUNT! (
        for /f "tokens=1,* delims=:" %%A in ('findstr /n "^" "!FILTERED_FILE!"') do (
            if "%%A"=="!CHOICE_NUM!" set "SELECTED_MODEL=%%B"
        )
    )
)

if defined SELECTED_MODEL (
    del "%RESPONSE_FILE%" 2>nul
    del "%MODELS_FILE%" 2>nul
    if exist "!FILTERED_FILE!" del /f /q "!FILTERED_FILE!" 2>nul
    goto :EOF
)

REM Trata como filtro se nao for numero valido
set "FILTER=!CHOICE!"
set "PAGE=0"
goto OR_MODEL_PAGE

:SELECT_GEMINI_MODEL
cls
echo.
echo   !BOLD!!BLUE!Selecionar Modelo - Google AI Studio!RESET!
echo   Buscando modelos...

set "RESPONSE_FILE=%TEMP%\gemini_models_%RANDOM%.txt"
curl -s -m 30 "https://generativelanguage.googleapis.com/v1beta/models" -H "X-goog-api-key: %APIKEY%" -o "%RESPONSE_FILE%" 2>nul

if not exist "%RESPONSE_FILE%" (
    echo   !RED![ERRO]!RESET! Falha ao buscar modelos.
    echo   Verifique a API Key ou conexao.
    pause
    goto :EOF
)
for %%Z in ("%RESPONSE_FILE%") do if %%~zZ LEQ 0 (
    echo   !RED![ERRO]!RESET! Falha ao buscar modelos.
    echo   Verifique a API Key ou conexao.
    del "%RESPONSE_FILE%" 2>nul
    pause
    goto :EOF
)

set "MODELS_FILE=%TEMP%\gemini_ids_%RANDOM%.txt"
set "PARSE_ERR_FILE=%TEMP%\gemini_parse_err_%RANDOM%.txt"
set "GEMINI_PARSE_ERR="
powershell -NoProfile -Command ^
"$j = Get-Content -Raw -LiteralPath $env:RESPONSE_FILE | ConvertFrom-Json; " ^
"if ($j.error) { $m = 'Erro da API'; if ($j.error.message) { $m = [string]$j.error.message } elseif ($j.error.status) { $m = [string]$j.error.status }; Write-Output $m; exit 2 }; " ^
"if (-not $j.models) { exit 1 }; " ^
"$ids = @(); foreach ($m in $j.models) { $id = [string]$m.name; if ($id) { $id = $id -replace '^models/',''; if ($id.Trim().Length -gt 0) { $ids += $id } } }; " ^
"if ($ids.Count -eq 0) { exit 1 }; " ^
"$ids | Set-Content -LiteralPath $env:MODELS_FILE -Encoding ascii" >nul 2>"%PARSE_ERR_FILE%"

if errorlevel 1 (
    echo   !RED![ERRO]!RESET! Falha ao processar resposta da API Gemini.
    for /f "usebackq delims=" %%E in ("%PARSE_ERR_FILE%") do (
        if not defined GEMINI_PARSE_ERR set "GEMINI_PARSE_ERR=%%E"
    )
    if defined GEMINI_PARSE_ERR echo   !GEMINI_PARSE_ERR!
    del "%RESPONSE_FILE%" 2>nul
    del "%MODELS_FILE%" 2>nul
    del "%PARSE_ERR_FILE%" 2>nul
    pause
    goto :EOF
)
del "%PARSE_ERR_FILE%" 2>nul

if not exist "%MODELS_FILE%" (
    echo   !RED![ERRO]!RESET! Nenhum modelo encontrado.
    del "%RESPONSE_FILE%" 2>nul
    pause
    goto :EOF
)

set /a TOTAL_MODELS=0
for /f "usebackq delims=" %%L in ("%MODELS_FILE%") do set /a TOTAL_MODELS+=1
if "!TOTAL_MODELS!"=="0" (
    echo   !RED![ERRO]!RESET! Nenhum modelo encontrado.
    del "%RESPONSE_FILE%" 2>nul
    del "%MODELS_FILE%" 2>nul
    pause
    goto :EOF
)

set "SELECTED_MODEL="
set "PAGE=0"
set "PAGE_SIZE=10"

:GEMINI_MODEL_PAGE
cls
echo.
echo   !BOLD!!BLUE!Selecionar Modelo - Google AI Studio!RESET!
echo   Modelos encontrados:
echo   !GRAY!------------------------------------------------!RESET!

set /a START=PAGE*PAGE_SIZE+1
set /a END=START+PAGE_SIZE-1
if !END! gtr !TOTAL_MODELS! set /a END=TOTAL_MODELS

for /f "tokens=1,* delims=:" %%A in ('findstr /n "^" "%MODELS_FILE%"') do (
    if %%A geq !START! (
        if %%A leq !END! (
            echo     !CYAN![%%A]!RESET! %%B
        )
    )
)

echo   !GRAY!------------------------------------------------!RESET!
echo   !GRAY![p]!RESET! Proxima pagina  !GRAY![a]!RESET! Pagina anterior
echo   !GRAY![0]!RESET! Cancelar
echo   !GRAY!------------------------------------------------!RESET!
echo.
set /p CHOICE="  Escolha: "

if "!CHOICE!"=="0" (
    del "%RESPONSE_FILE%" 2>nul
    del "%MODELS_FILE%" 2>nul
    goto :EOF
)
if /i "!CHOICE!"=="p" (
    if !END! lss !TOTAL_MODELS! set /a PAGE+=1
    goto GEMINI_MODEL_PAGE
)
if /i "!CHOICE!"=="a" (
    if !PAGE! gtr 0 set /a PAGE-=1
    goto GEMINI_MODEL_PAGE
)

echo(!CHOICE!| findstr /R "^[0-9][0-9]*$" >nul
if not errorlevel 1 (
    set /a CHOICE_NUM=!CHOICE!
    if !CHOICE_NUM! geq 1 if !CHOICE_NUM! leq !TOTAL_MODELS! (
        for /f "tokens=1,* delims=:" %%A in ('findstr /n "^" "%MODELS_FILE%"') do (
            if "%%A"=="!CHOICE_NUM!" set "SELECTED_MODEL=%%B"
        )
    )
)

if defined SELECTED_MODEL (
    del "%RESPONSE_FILE%" 2>nul
    del "%MODELS_FILE%" 2>nul
    goto :EOF
)
goto GEMINI_MODEL_PAGE

:SELECT_OPENAI_MODEL
cls
echo.
echo   !BOLD!!BLUE!Selecionar Modelo - OpenAI!RESET!
echo   Buscando modelos...

set "RESPONSE_FILE=%TEMP%\openai_models_%RANDOM%.txt"
curl -s -m 30 "https://api.openai.com/v1/models" -H "Authorization: Bearer %APIKEY%" -o "%RESPONSE_FILE%" 2>nul

if not exist "%RESPONSE_FILE%" (
    echo   !RED![ERRO]!RESET! Falha ao buscar modelos.
    echo   Verifique a API Key ou conexao.
    pause
    goto :EOF
)
for %%Z in ("%RESPONSE_FILE%") do if %%~zZ LEQ 0 (
    echo   !RED![ERRO]!RESET! Falha ao buscar modelos.
    echo   Verifique a API Key ou conexao.
    del "%RESPONSE_FILE%" 2>nul
    pause
    goto :EOF
)

set "MODELS_FILE=%TEMP%\openai_ids_%RANDOM%.txt"
set "PARSE_ERR_FILE=%TEMP%\openai_parse_err_%RANDOM%.txt"
set "OPENAI_PARSE_ERR="
powershell -NoProfile -Command ^
"$j = Get-Content -Raw -LiteralPath $env:RESPONSE_FILE | ConvertFrom-Json; " ^
"if ($j.error) { $m = 'Erro da API'; if ($j.error.message) { $m = [string]$j.error.message } elseif ($j.error.code) { $m = [string]$j.error.code }; Write-Output $m; exit 2 }; " ^
"if (-not $j.data) { exit 1 }; " ^
"$ids = @(); foreach ($m in $j.data) { $id = [string]$m.id; if ($id -and $id.Trim().Length -gt 0) { $ids += $id } }; " ^
"if ($ids.Count -eq 0) { exit 1 }; " ^
"$ids | Set-Content -LiteralPath $env:MODELS_FILE -Encoding ascii" >nul 2>"%PARSE_ERR_FILE%"

if errorlevel 1 (
    echo   !RED![ERRO]!RESET! Falha ao processar resposta da API OpenAI.
    for /f "usebackq delims=" %%E in ("%PARSE_ERR_FILE%") do (
        if not defined OPENAI_PARSE_ERR set "OPENAI_PARSE_ERR=%%E"
    )
    if defined OPENAI_PARSE_ERR echo   !OPENAI_PARSE_ERR!
    del "%RESPONSE_FILE%" 2>nul
    del "%MODELS_FILE%" 2>nul
    del "%PARSE_ERR_FILE%" 2>nul
    pause
    goto :EOF
)
del "%PARSE_ERR_FILE%" 2>nul

if not exist "%MODELS_FILE%" (
    echo   !RED![ERRO]!RESET! Nenhum modelo encontrado.
    del "%RESPONSE_FILE%" 2>nul
    pause
    goto :EOF
)

set /a TOTAL_MODELS=0
for /f "usebackq delims=" %%L in ("%MODELS_FILE%") do set /a TOTAL_MODELS+=1
if "!TOTAL_MODELS!"=="0" (
    echo   !RED![ERRO]!RESET! Nenhum modelo encontrado.
    del "%RESPONSE_FILE%" 2>nul
    del "%MODELS_FILE%" 2>nul
    pause
    goto :EOF
)

set "SELECTED_MODEL="
set "PAGE=0"
set "PAGE_SIZE=10"

:OPENAI_MODEL_PAGE
cls
echo.
echo   !BOLD!!BLUE!Selecionar Modelo - OpenAI!RESET!
echo   Modelos encontrados:
echo   !GRAY!------------------------------------------------!RESET!

set /a START=PAGE*PAGE_SIZE+1
set /a END=START+PAGE_SIZE-1
if !END! gtr !TOTAL_MODELS! set /a END=TOTAL_MODELS

for /f "tokens=1,* delims=:" %%A in ('findstr /n "^" "%MODELS_FILE%"') do (
    if %%A geq !START! (
        if %%A leq !END! (
            echo     !CYAN![%%A]!RESET! %%B
        )
    )
)

echo   !GRAY!------------------------------------------------!RESET!
echo   !GRAY![p]!RESET! Proxima pagina  !GRAY![a]!RESET! Pagina anterior
echo   !GRAY![0]!RESET! Cancelar
echo   !GRAY!------------------------------------------------!RESET!
echo.
set /p CHOICE="  Escolha: "

if "!CHOICE!"=="0" (
    del "%RESPONSE_FILE%" 2>nul
    del "%MODELS_FILE%" 2>nul
    goto :EOF
)
if /i "!CHOICE!"=="p" (
    if !END! lss !TOTAL_MODELS! set /a PAGE+=1
    goto OPENAI_MODEL_PAGE
)
if /i "!CHOICE!"=="a" (
    if !PAGE! gtr 0 set /a PAGE-=1
    goto OPENAI_MODEL_PAGE
)

echo(!CHOICE!| findstr /R "^[0-9][0-9]*$" >nul
if not errorlevel 1 (
    set /a CHOICE_NUM=!CHOICE!
    if !CHOICE_NUM! geq 1 if !CHOICE_NUM! leq !TOTAL_MODELS! (
        for /f "tokens=1,* delims=:" %%A in ('findstr /n "^" "%MODELS_FILE%"') do (
            if "%%A"=="!CHOICE_NUM!" set "SELECTED_MODEL=%%B"
        )
    )
)

if defined SELECTED_MODEL (
    del "%RESPONSE_FILE%" 2>nul
    del "%MODELS_FILE%" 2>nul
    goto :EOF
)
goto OPENAI_MODEL_PAGE

:SELECT_NVIDIA_MODEL
cls
echo.
echo   !BOLD!!BLUE!Selecionar Modelo - NVIDIA NGC!RESET!
echo   Buscando modelos...

set "RESPONSE_FILE=%TEMP%\nvidia_models_%RANDOM%.txt"
curl -s -m 30 "https://integrate.api.nvidia.com/v1/models" -H "Authorization: Bearer %APIKEY%" -o "%RESPONSE_FILE%" 2>nul

if not exist "%RESPONSE_FILE%" (
    echo   !RED![ERRO]!RESET! Falha ao buscar modelos.
    echo   Verifique a API Key ou conexao.
    pause
    goto :EOF
)
for %%Z in ("%RESPONSE_FILE%") do if %%~zZ LEQ 0 (
    echo   !RED![ERRO]!RESET! Falha ao buscar modelos.
    echo   Verifique a API Key ou conexao.
    del "%RESPONSE_FILE%" 2>nul
    pause
    goto :EOF
)

set "MODELS_FILE=%TEMP%\nvidia_ids_%RANDOM%.txt"
set "PARSE_ERR_FILE=%TEMP%\nvidia_parse_err_%RANDOM%.txt"
set "NVIDIA_PARSE_ERR="
powershell -NoProfile -Command ^
"$j = Get-Content -Raw -LiteralPath $env:RESPONSE_FILE | ConvertFrom-Json; " ^
"if ($j.error) { $m = 'Erro da API'; if ($j.error.message) { $m = [string]$j.error.message } elseif ($j.error) { $m = [string]$j.error }; Write-Output $m; exit 2 }; " ^
"if (-not $j.data) { exit 1 }; " ^
"$ids = @(); foreach ($m in $j.data) { $id = [string]$m.id; if ($id -and $id.Trim().Length -gt 0) { $ids += $id } }; " ^
"if ($ids.Count -eq 0) { exit 1 }; " ^
"$ids | Set-Content -LiteralPath $env:MODELS_FILE -Encoding ascii" >nul 2>"%PARSE_ERR_FILE%"

if errorlevel 1 (
    echo   !RED![ERRO]!RESET! Falha ao processar resposta da API NVIDIA.
    for /f "usebackq delims=" %%E in ("%PARSE_ERR_FILE%") do (
        if not defined NVIDIA_PARSE_ERR set "NVIDIA_PARSE_ERR=%%E"
    )
    if defined NVIDIA_PARSE_ERR echo   !NVIDIA_PARSE_ERR!
    del "%RESPONSE_FILE%" 2>nul
    del "%MODELS_FILE%" 2>nul
    del "%PARSE_ERR_FILE%" 2>nul
    pause
    goto :EOF
)
del "%PARSE_ERR_FILE%" 2>nul

if not exist "%MODELS_FILE%" (
    echo   !RED![ERRO]!RESET! Nenhum modelo encontrado.
    del "%RESPONSE_FILE%" 2>nul
    pause
    goto :EOF
)

set /a TOTAL_MODELS=0
for /f "usebackq delims=" %%L in ("%MODELS_FILE%") do set /a TOTAL_MODELS+=1
if "!TOTAL_MODELS!"=="0" (
    echo   !RED![ERRO]!RESET! Nenhum modelo encontrado.
    del "%RESPONSE_FILE%" 2>nul
    del "%MODELS_FILE%" 2>nul
    pause
    goto :EOF
)

set "SELECTED_MODEL="
set "FILTER="
set "PAGE=0"
set "PAGE_SIZE=15"
set "FILTERED_FILE=%TEMP%\nvidia_filtered_%RANDOM%.txt"

:NV_MODEL_PAGE
REM Aplica filtro
if exist "!FILTERED_FILE!" del /f /q "!FILTERED_FILE!" 2>nul
set /a FILTERED_COUNT=0
for /f "tokens=1,* delims=:" %%A in ('findstr /n "^" "%MODELS_FILE%"') do (
    set "MATCH_LINE=%%B"
    call :NV_MATCH_FILTER
    if defined NV_MATCH (
        echo !MATCH_LINE! >> "!FILTERED_FILE!"
        set /a FILTERED_COUNT+=1
    )
)
if "!FILTERED_COUNT!"=="0" (
    echo   Nenhum modelo corresponde ao filtro.
)

set /a TOTAL_PAGES=(!FILTERED_COUNT! + %PAGE_SIZE% - 1) / %PAGE_SIZE%
if !TOTAL_PAGES! lss 1 set /a TOTAL_PAGES=1

cls
echo.
echo   !BOLD!!BLUE!Selecionar Modelo - NVIDIA NGC!RESET!
echo   !GRAY!------------------------------------------------!RESET!
if defined FILTER (
    echo   Filtro: !CYAN!!FILTER!!RESET! (!FILTERED_COUNT! resultados)
) else (
    echo   Todos os modelos (!FILTERED_COUNT!)
)
echo   Pagina !PAGE! de !TOTAL_PAGES!
echo   !GRAY!------------------------------------------------!RESET!

set /a START=PAGE*PAGE_SIZE+1
set /a END=START+PAGE_SIZE-1
set /a DISP_COUNT=0
for /f "tokens=1,* delims=:" %%A in ('findstr /n "^" "!FILTERED_FILE!"') do (
    if %%A geq !START! (
        if %%A leq !END! (
            echo     !CYAN![%%A]!RESET! %%B
            set /a DISP_COUNT+=1
        )
    )
)

echo   !GRAY!------------------------------------------------!RESET!
echo   !GRAY![p]!RESET! Proxima pagina  !GRAY![a]!RESET! Pagina anterior
if defined FILTER (
    echo   !GRAY![n]!RESET! Limpar filtro
)
echo   !GRAY![0]!RESET! Cancelar
echo   !GRAY!------------------------------------------------!RESET!
echo.
set /p CHOICE="  Escolha ou digite para filtrar: "

if "!CHOICE!"=="0" (
    del "%RESPONSE_FILE%" 2>nul
    del "%MODELS_FILE%" 2>nul
    if exist "!FILTERED_FILE!" del /f /q "!FILTERED_FILE!" 2>nul
    goto :EOF
)
if /i "!CHOICE!"=="p" (
    if !END! lss !FILTERED_COUNT! set /a PAGE+=1
    goto NV_MODEL_PAGE
)
if /i "!CHOICE!"=="a" (
    if !PAGE! gtr 0 set /a PAGE-=1
    goto NV_MODEL_PAGE
)
if /i "!CHOICE!"=="n" (
    set "FILTER="
    set "PAGE=0"
    goto NV_MODEL_PAGE
)

echo(!CHOICE!| findstr /R "^[0-9][0-9]*$" >nul
if not errorlevel 1 (
    set /a CHOICE_NUM=!CHOICE!
    if !CHOICE_NUM! geq 1 if !CHOICE_NUM! leq !FILTERED_COUNT! (
        for /f "tokens=1,* delims=:" %%A in ('findstr /n "^" "!FILTERED_FILE!"') do (
            if "%%A"=="!CHOICE_NUM!" set "SELECTED_MODEL=%%B"
        )
    )
)

if defined SELECTED_MODEL (
    del "%RESPONSE_FILE%" 2>nul
    del "%MODELS_FILE%" 2>nul
    if exist "!FILTERED_FILE!" del /f /q "!FILTERED_FILE!" 2>nul
    goto :EOF
)

REM Trata como filtro se nao for numero valido
set "FILTER=!CHOICE!"
set "PAGE=0"
goto NV_MODEL_PAGE

:NV_MATCH_FILTER
set "NV_MATCH="
if not defined FILTER (
    set "NV_MATCH=1"
    goto :EOF
)
echo !MATCH_LINE! | findstr /I /C:"!FILTER!" >nul
if not errorlevel 1 set "NV_MATCH=1"
goto :EOF

:NORMALIZE_PROVIDER_FILES
for %%F in ("%CONFIG_DIR%\settings-*") do (
    if exist "%%~fF" (
        if /i not "%%~xF"==".json" (
            if /i not "%%~nxF"=="settings.json" (
                if /i not "%%~nxF"=="settings.local.json" (
                    if not exist "%%~fF.json" ren "%%~fF" "%%~nxF.json" >nul 2>&1
                )
            )
        )
    )
)
goto :EOF
