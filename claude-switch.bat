@echo off
setlocal enabledelayedexpansion

set "CONFIG_DIR=%USERPROFILE%\.claude"
set "SETTINGS=%CONFIG_DIR%\settings.json"

if not exist "%CONFIG_DIR%" mkdir "%CONFIG_DIR%"
for /f %%e in ('echo prompt $E ^| cmd') do set "ESC=%%e"
set "GREEN="
set "RESET="
if defined ESC (
    set "GREEN=!ESC![92m"
    set "RESET=!ESC![0m"
)

:MENU
cls
echo.
echo ==========================================
echo   Claude Code - Provider Manager
echo ==========================================

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

if %COUNT%==0 (
    echo   Nenhum provider configurado ainda.
) else (
    echo   Providers disponiveis:
    echo.
    for /L %%I in (1,1,%COUNT%) do (
        call :PRINT_PROVIDER %%I "!LABEL_%%I!"
    )
)

echo.
echo ------------------------------------------
set /a OPT_NEW=%COUNT%+1
set /a OPT_DEL=%COUNT%+2
set /a OPT_NATIVE=%COUNT%+3
set /a OPT_STATUS=%COUNT%+4
echo   [!OPT_NEW!] Adicionar novo provider
echo   [!OPT_DEL!] Remover provider
echo   [!OPT_NATIVE!] Claude padrao (Anthropic login)
echo   [!OPT_STATUS!] Ver provider atual
echo   [0] Sair
echo ------------------------------------------

echo.
echo   Ativo: !CURRENT_PROVIDER!
if defined CURRENT_MODEL echo   Modelo: !CURRENT_MODEL!

echo.
set /p CHOICE="  Escolha: "

if "%CHOICE%"=="0" goto FIM
if "%CHOICE%"=="%OPT_NEW%" goto NOVO
if "%CHOICE%"=="%OPT_DEL%" goto REMOVER
if "%CHOICE%"=="%OPT_NATIVE%" goto USE_NATIVE_ANTHROPIC
if "%CHOICE%"=="%OPT_STATUS%" goto STATUS

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
    if defined GREEN (
        echo   !GREEN![!IDX!] !LBL!  [v] ativo!RESET!
    ) else (
        echo   [!IDX!] !LBL!  [ativo]
    )
    goto :EOF
)
echo   [!IDX!] !LBL!
goto :EOF

:ATIVAR
cls
echo.
echo  Ativando %~2...
set "TMP_SETTINGS=%SETTINGS%.tmp"
copy /Y "%CONFIG_DIR%\%~1.json" "!TMP_SETTINGS!" >nul
move /Y "!TMP_SETTINGS!" "%SETTINGS%" >nul
echo.
echo ==========================================
echo   [OK] Provider ativo: %~2
echo ==========================================
echo.
echo   IMPORTANTE: Reinicie o Claude Code!
echo   Feche e abra novamente para aplicar.
echo ==========================================
echo.
pause
goto :EOF

:USE_NATIVE_ANTHROPIC
cls
echo.
echo  Ativando Claude Code padrao (Anthropic login)...
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
echo ==========================================
echo   [OK] Claude Code padrao ativado
echo ==========================================
echo   Proximos passos:
echo   1^) Reinicie o Claude Code
echo   2^) Rode /login ou claude login
echo   3^) Selecione Anthropic
echo ==========================================
echo.
pause
goto MENU

:NOVO
cls
echo.
echo ==========================================
echo   Adicionar Novo Provider
echo ==========================================
echo.
echo   [1] MiniMax      - api.minimax.io/anthropic
echo   [2] OpenRouter  - openrouter.ai/api
echo   [3] Anthropic   - API key oficial
echo   [4] Z.AI / GLM  - api.z.ai/api/anthropic
echo   [5] Google AI Studio (Gemini)
echo   [6] OpenAI (GPT)
echo   [7] Outro       - digitar manualmente
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

echo.
set /p PNAME="  Nome do provider [!DEF_NAME!]: "
if "!PNAME!"=="" set "PNAME=!DEF_NAME!"
set "PNAME=!PNAME:\=-!"
set "PNAME=!PNAME:/=-!"
set "PNAME=!PNAME::=-!"
set "PNAME=!PNAME:*=-!"
set "PNAME=!PNAME:?=-!"
set "PNAME=!PNAME:<=-!"
set "PNAME=!PNAME:>=-!"
set "PNAME=!PNAME:|=-!"
for /f "tokens=* delims= " %%A in ("!PNAME!") do set "PNAME=%%A"
:TRIM_PNAME_RIGHT
if "!PNAME:~-1!"==" " (
    set "PNAME=!PNAME:~0,-1!"
    goto TRIM_PNAME_RIGHT
)
if "!PNAME!"=="" set "PNAME=!DEF_NAME!"

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
echo ==========================================
echo   Confirmar Configuracao
echo ==========================================
echo   Provider: !PNAME!
echo   Endpoint: !BASE_URL!
echo.
echo   Modelos selecionados:
echo   Principal:   !MODEL_MAIN!
echo   Rapido:      !MODEL_FAST!
echo   Sonnet:      !MODEL_SONNET!
echo   Opus:        !MODEL_OPUS!
echo   Haiku:       !MODEL_HAIKU!
echo ==========================================
echo   [ENTER] Confirmar
echo   [n] Cancelar
echo.
set /p CONFIRM="  Escolha: "
if /i "!CONFIRM!"=="n" goto MENU

set "OUT=%CONFIG_DIR%\settings-!PNAME!.json"

if "!NATIVE!"=="1" (
    (
        echo {
        echo   "env": {
        echo     "ANTHROPIC_API_KEY": "!APIKEY!",
        echo     "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC": "1"
        echo   },
        echo   "autoUpdatesChannel": "latest"
        echo }
    ) > "!OUT!"
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
    ) > "!OUT!"
)

echo.
echo  [OK] Provider "!PNAME!" salvo!
echo.
set /p ATIVAR_NOW="  Ativar agora? (s/n): "
if /i "!ATIVAR_NOW!"=="s" (
    set "TMP_SETTINGS=%SETTINGS%.tmp"
    copy /Y "!OUT!" "!TMP_SETTINGS!" >nul
    move /Y "!TMP_SETTINGS!" "%SETTINGS%" >nul
    echo.
    echo ==========================================
    echo   [OK] Provider "!PNAME!" ativado!
    echo ==========================================
    echo   IMPORTANTE: Reinicie o Claude Code!
    echo ==========================================
)
echo.
pause
goto MENU

:REMOVER
cls
echo.
echo  Qual provider remover?
echo.
set C2=0
for %%F in ("%CONFIG_DIR%\settings-*.json") do (
    set "RL=%%~nF"
    if /i not "!RL!"=="settings-before-native-anthropic" (
        set /a C2+=1
        set "RF_!C2!=%%~nF"
        set "RL=!RL:settings-=!"
        set "RL_!C2!=!RL!"
        echo  [!C2!] !RL!
    )
)
echo  [0] Cancelar
echo.
set /p RD="  Escolha: "
if "!RD!"=="0" goto MENU
for /L %%I in (1,1,%C2%) do (
    if "!RD!"=="%%I" (
        set /p CF="  Remover !RL_%%I!? (s/n): "
        if /i "!CF!"=="s" (
            del "%CONFIG_DIR%\!RF_%%I!.json"
            echo  [OK] Removido.
        )
    )
)
echo.
pause
goto MENU

:STATUS
cls
echo.
echo  settings.json atual:
echo  ----------------------------------------
if not exist "%SETTINGS%" (
    echo  settings.json nao encontrado!
) else (
    powershell -NoProfile -Command ^
    "$j = Get-Content -Raw -LiteralPath '%SETTINGS%' | ConvertFrom-Json; " ^
    "if ($j.env.ANTHROPIC_AUTH_TOKEN) { $v = [string]$j.env.ANTHROPIC_AUTH_TOKEN; $j.env.ANTHROPIC_AUTH_TOKEN = $v.Substring(0, [Math]::Min(4, $v.Length)) + '****************************' }; " ^
    "if ($j.env.ANTHROPIC_API_KEY) { $v = [string]$j.env.ANTHROPIC_API_KEY; $j.env.ANTHROPIC_API_KEY = $v.Substring(0, [Math]::Min(4, $v.Length)) + '****************************' }; " ^
    "$j | ConvertTo-Json -Depth 8"
)
echo.
pause
goto MENU

:FIM
cls
echo.
echo  Ate logo!
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
echo ==========================================
echo   [ERRO] Chave OpenRouter invalida ou sem acesso.
if defined OR_KEY_ERR echo   !OR_KEY_ERR!
if not defined OR_KEY_ERR echo   Falha na autenticacao OpenRouter.
echo ==========================================
del "%KEY_CHECK_FILE%" 2>nul
del "%KEY_ERR_FILE%" 2>nul
goto :EOF

:SELECT_OPENROUTER_MODEL
cls
echo.
echo ==========================================
echo   Selecionar Modelo - OpenRouter
echo ==========================================
echo   Buscando modelos...

set "RESPONSE_FILE=%TEMP%\openrouter_models_%RANDOM%.txt"
curl -s -m 30 "https://openrouter.ai/api/v1/models" -H "Authorization: Bearer %APIKEY%" -o "%RESPONSE_FILE%" 2>nul

if not exist "%RESPONSE_FILE%" (
    echo   [ERRO] Falha ao buscar modelos.
    echo   Verifique a API Key ou conexao.
    echo ==========================================
    pause
    goto :EOF
)
for %%Z in ("%RESPONSE_FILE%") do if %%~zZ LEQ 0 (
    echo   [ERRO] Falha ao buscar modelos.
    echo   Verifique a API Key ou conexao.
    del "%RESPONSE_FILE%" 2>nul
    echo ==========================================
    pause
    goto :EOF
)

set "MODELS_FILE=%TEMP%\openrouter_ids_%RANDOM%.txt"
set "PARSE_ERR_FILE=%TEMP%\openrouter_parse_err_%RANDOM%.txt"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\extract-openrouter-models.ps1" "%RESPONSE_FILE%" "%MODELS_FILE%" >nul 2>"%PARSE_ERR_FILE%"

if errorlevel 1 (
    echo   [ERRO] Falha ao processar resposta da API OpenRouter.
    del "%RESPONSE_FILE%" 2>nul
    del "%MODELS_FILE%" 2>nul
    del "%PARSE_ERR_FILE%" 2>nul
    echo ==========================================
    pause
    goto :EOF
)
del "%PARSE_ERR_FILE%" 2>nul

if not exist "%MODELS_FILE%" (
    echo   [ERRO] Nenhum modelo encontrado.
    del "%RESPONSE_FILE%" 2>nul
    echo ==========================================
    pause
    goto :EOF
)

set /a TOTAL_MODELS=0
for /f "usebackq delims=" %%L in ("%MODELS_FILE%") do set /a TOTAL_MODELS+=1
if "!TOTAL_MODELS!"=="0" (
    echo   [ERRO] Nenhum modelo encontrado.
    del "%RESPONSE_FILE%" 2>nul
    del "%MODELS_FILE%" 2>nul
    echo ==========================================
    pause
    goto :EOF
)

set "SELECTED_MODEL="
set "PAGE=0"
set "PAGE_SIZE=10"

:OR_MODEL_PAGE
cls
echo.
echo ==========================================
echo   Selecionar Modelo - OpenRouter
echo ==========================================
echo   Modelos encontrados:
echo ==========================================

set /a START=PAGE*PAGE_SIZE+1
set /a END=START+PAGE_SIZE-1
if !END! gtr !TOTAL_MODELS! set /a END=TOTAL_MODELS

for /f "tokens=1,* delims=:" %%A in ('findstr /n "^" "%MODELS_FILE%"') do (
    if %%A geq !START! (
        if %%A leq !END! (
            echo   [%%A] %%B
        )
    )
)

echo ==========================================
echo   [p] Proxima pagina
echo   [a] Pagina anterior
echo   [0] Cancelar
echo ==========================================
echo.
set /p CHOICE="  Escolha: "

if "!CHOICE!"=="0" (
    del "%RESPONSE_FILE%" 2>nul
    del "%MODELS_FILE%" 2>nul
    goto :EOF
)
if /i "!CHOICE!"=="p" (
    if !END! lss !TOTAL_MODELS! set /a PAGE+=1
    goto OR_MODEL_PAGE
)
if /i "!CHOICE!"=="a" (
    if !PAGE! gtr 0 set /a PAGE-=1
    goto OR_MODEL_PAGE
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
goto OR_MODEL_PAGE

:SELECT_GEMINI_MODEL
cls
echo.
echo ==========================================
echo   Selecionar Modelo - Google AI Studio
echo ==========================================
echo   Buscando modelos...

set "RESPONSE_FILE=%TEMP%\gemini_models_%RANDOM%.txt"
curl -s -m 30 "https://generativelanguage.googleapis.com/v1beta/models" -H "X-goog-api-key: %APIKEY%" -o "%RESPONSE_FILE%" 2>nul

if not exist "%RESPONSE_FILE%" (
    echo   [ERRO] Falha ao buscar modelos.
    echo   Verifique a API Key ou conexao.
    echo ==========================================
    pause
    goto :EOF
)
for %%Z in ("%RESPONSE_FILE%") do if %%~zZ LEQ 0 (
    echo   [ERRO] Falha ao buscar modelos.
    echo   Verifique a API Key ou conexao.
    del "%RESPONSE_FILE%" 2>nul
    echo ==========================================
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
    echo   [ERRO] Falha ao processar resposta da API Gemini.
    for /f "usebackq delims=" %%E in ("%PARSE_ERR_FILE%") do (
        if not defined GEMINI_PARSE_ERR set "GEMINI_PARSE_ERR=%%E"
    )
    if defined GEMINI_PARSE_ERR echo   !GEMINI_PARSE_ERR!
    del "%RESPONSE_FILE%" 2>nul
    del "%MODELS_FILE%" 2>nul
    del "%PARSE_ERR_FILE%" 2>nul
    echo ==========================================
    pause
    goto :EOF
)
del "%PARSE_ERR_FILE%" 2>nul

if not exist "%MODELS_FILE%" (
    echo   [ERRO] Nenhum modelo encontrado.
    del "%RESPONSE_FILE%" 2>nul
    echo ==========================================
    pause
    goto :EOF
)

set /a TOTAL_MODELS=0
for /f "usebackq delims=" %%L in ("%MODELS_FILE%") do set /a TOTAL_MODELS+=1
if "!TOTAL_MODELS!"=="0" (
    echo   [ERRO] Nenhum modelo encontrado.
    del "%RESPONSE_FILE%" 2>nul
    del "%MODELS_FILE%" 2>nul
    echo ==========================================
    pause
    goto :EOF
)

set "SELECTED_MODEL="
set "PAGE=0"
set "PAGE_SIZE=10"

:GEMINI_MODEL_PAGE
cls
echo.
echo ==========================================
echo   Selecionar Modelo - Google AI Studio
echo ==========================================
echo   Modelos encontrados:
echo ==========================================

set /a START=PAGE*PAGE_SIZE+1
set /a END=START+PAGE_SIZE-1
if !END! gtr !TOTAL_MODELS! set /a END=TOTAL_MODELS

for /f "tokens=1,* delims=:" %%A in ('findstr /n "^" "%MODELS_FILE%"') do (
    if %%A geq !START! (
        if %%A leq !END! (
            echo   [%%A] %%B
        )
    )
)

echo ==========================================
echo   [p] Proxima pagina
echo   [a] Pagina anterior
echo   [0] Cancelar
echo ==========================================
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
echo ==========================================
echo   Selecionar Modelo - OpenAI
echo ==========================================
echo   Buscando modelos...

set "RESPONSE_FILE=%TEMP%\openai_models_%RANDOM%.txt"
curl -s -m 30 "https://api.openai.com/v1/models" -H "Authorization: Bearer %APIKEY%" -o "%RESPONSE_FILE%" 2>nul

if not exist "%RESPONSE_FILE%" (
    echo   [ERRO] Falha ao buscar modelos.
    echo   Verifique a API Key ou conexao.
    echo ==========================================
    pause
    goto :EOF
)
for %%Z in ("%RESPONSE_FILE%") do if %%~zZ LEQ 0 (
    echo   [ERRO] Falha ao buscar modelos.
    echo   Verifique a API Key ou conexao.
    del "%RESPONSE_FILE%" 2>nul
    echo ==========================================
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
    echo   [ERRO] Falha ao processar resposta da API OpenAI.
    for /f "usebackq delims=" %%E in ("%PARSE_ERR_FILE%") do (
        if not defined OPENAI_PARSE_ERR set "OPENAI_PARSE_ERR=%%E"
    )
    if defined OPENAI_PARSE_ERR echo   !OPENAI_PARSE_ERR!
    del "%RESPONSE_FILE%" 2>nul
    del "%MODELS_FILE%" 2>nul
    del "%PARSE_ERR_FILE%" 2>nul
    echo ==========================================
    pause
    goto :EOF
)
del "%PARSE_ERR_FILE%" 2>nul

if not exist "%MODELS_FILE%" (
    echo   [ERRO] Nenhum modelo encontrado.
    del "%RESPONSE_FILE%" 2>nul
    echo ==========================================
    pause
    goto :EOF
)

set /a TOTAL_MODELS=0
for /f "usebackq delims=" %%L in ("%MODELS_FILE%") do set /a TOTAL_MODELS+=1
if "!TOTAL_MODELS!"=="0" (
    echo   [ERRO] Nenhum modelo encontrado.
    del "%RESPONSE_FILE%" 2>nul
    del "%MODELS_FILE%" 2>nul
    echo ==========================================
    pause
    goto :EOF
)

set "SELECTED_MODEL="
set "PAGE=0"
set "PAGE_SIZE=10"

:OPENAI_MODEL_PAGE
cls
echo.
echo ==========================================
echo   Selecionar Modelo - OpenAI
echo ==========================================
echo   Modelos encontrados:
echo ==========================================

set /a START=PAGE*PAGE_SIZE+1
set /a END=START+PAGE_SIZE-1
if !END! gtr !TOTAL_MODELS! set /a END=TOTAL_MODELS

for /f "tokens=1,* delims=:" %%A in ('findstr /n "^" "%MODELS_FILE%"') do (
    if %%A geq !START! (
        if %%A leq !END! (
            echo   [%%A] %%B
        )
    )
)

echo ==========================================
echo   [p] Proxima pagina
echo   [a] Pagina anterior
echo   [0] Cancelar
echo ==========================================
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
