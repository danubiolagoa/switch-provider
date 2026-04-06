@echo off
setlocal enabledelayedexpansion

set "CONFIG_DIR=%USERPROFILE%\.claude"
set "SETTINGS=%CONFIG_DIR%\settings.json"

if not exist "%CONFIG_DIR%" mkdir "%CONFIG_DIR%"

:MENU
cls
echo.
echo ==========================================
echo   Claude Code - Provider Manager
echo ==========================================

set COUNT=0
for %%F in ("%CONFIG_DIR%\settings-*.json") do (
    set /a COUNT+=1
    set "FILE_!COUNT!=%%~nF"
    set "LABEL=%%~nF"
    set "LABEL=!LABEL:settings-=!"
    set "LABEL_!COUNT!=!LABEL!"
)

if %COUNT%==0 (
    echo   Nenhum provider configurado ainda.
) else (
    echo   Providers disponiveis:
    echo.
    for /L %%I in (1,1,%COUNT%) do (
        echo   [%%I] !LABEL_%%I!
    )
)

echo.
echo ------------------------------------------
set /a OPT_NEW=%COUNT%+1
set /a OPT_DEL=%COUNT%+2
set /a OPT_STATUS=%COUNT%+3
echo   [!OPT_NEW!] Adicionar novo provider
echo   [!OPT_DEL!] Remover provider
echo   [!OPT_STATUS!] Ver provider atual
echo   [0] Sair
echo ------------------------------------------

if exist "%SETTINGS%" (
    for /f "tokens=2 delims=:," %%A in ('findstr "ANTHROPIC_BASE_URL" "%SETTINGS%" 2^>nul') do (
        set "CUR=%%A"
        set "CUR=!CUR: =!"
        set "CUR=!CUR:"=!"
        echo.
        echo   Ativo: !CUR!
        goto SKIP
    )
    for /f "tokens=1" %%A in ('findstr "ANTHROPIC_API_KEY" "%SETTINGS%" 2^>nul') do (
        echo.
        echo   Ativo: Anthropic (nativo)
        goto SKIP
    )
)
:SKIP

echo.
set /p CHOICE="  Escolha: "

if "%CHOICE%"=="0" goto FIM
if "%CHOICE%"=="%OPT_NEW%" goto NOVO
if "%CHOICE%"=="%OPT_DEL%" goto REMOVER
if "%CHOICE%"=="%OPT_STATUS%" goto STATUS

for /L %%I in (1,1,%COUNT%) do (
    if "%CHOICE%"=="%%I" (
        call :ATIVAR "!FILE_%%I!" "!LABEL_%%I!"
        goto MENU
    )
)
goto MENU

:ATIVAR
cls
echo.
echo  Ativando %~2...
copy /Y "%CONFIG_DIR%\%~1.json" "%SETTINGS%" >nul
echo  [OK] Provider ativo: %~2
echo.
pause
goto :EOF

:NOVO
cls
echo.
echo ==========================================
echo   Adicionar Novo Provider
echo ==========================================
echo.
echo   [1] MiniMax      - api.minimax.io/anthropic
echo   [2] OpenRouter   - openrouter.ai/api/v1
echo   [3] Anthropic    - API key oficial
echo   [4] Z.AI / GLM   - api.z.ai/api/anthropic
echo   [5] Outro        - digitar manualmente
echo.
set /p EP="  Endpoint: "

set "BASE_URL="
set "DEF_MODEL="
set "DEF_NAME=custom"
set "NATIVE=0"

if "%EP%"=="1" (
    set "BASE_URL=https://api.minimax.io/anthropic"
    set "DEF_MODEL=MiniMax-M2.7"
    set "DEF_NAME=minimax"
)
if "%EP%"=="2" (
    set "BASE_URL=https://openrouter.ai/api/v1"
    set "DEF_MODEL=qwen/qwen3-235b-a22b:free"
    set "DEF_NAME=openrouter"
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
    echo.
    set /p BASE_URL="  Digite o endpoint: "
)

echo.
set /p PNAME="  Nome do provider [!DEF_NAME!]: "
if "!PNAME!"=="" set "PNAME=!DEF_NAME!"

echo.
set /p APIKEY="  Cole sua API Key: "

set "MODEL=!DEF_MODEL!"
if "!NATIVE!"=="0" (
    echo.
    set /p MODEL="  Modelo [!DEF_MODEL!]: "
    if "!MODEL!"=="" set "MODEL=!DEF_MODEL!"
)

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
        echo     "API_TIMEOUT_MS": "3000000",
        echo     "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC": "1",
        echo     "ANTHROPIC_MODEL": "!MODEL!",
        echo     "ANTHROPIC_SMALL_FAST_MODEL": "!MODEL!",
        echo     "ANTHROPIC_DEFAULT_SONNET_MODEL": "!MODEL!",
        echo     "ANTHROPIC_DEFAULT_OPUS_MODEL": "!MODEL!",
        echo     "ANTHROPIC_DEFAULT_HAIKU_MODEL": "!MODEL!"
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
    copy /Y "!OUT!" "%SETTINGS%" >nul
    echo  [OK] Provider "!PNAME!" ativado!
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
    set /a C2+=1
    set "RF_!C2!=%%~nF"
    set "RL=%%~nF"
    set "RL=!RL:settings-=!"
    set "RL_!C2!=!RL!"
    echo  [!C2!] !RL!
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
    type "%SETTINGS%"
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
