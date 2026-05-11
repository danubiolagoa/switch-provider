$ErrorActionPreference = "Stop"

$Repo = if ($env:SWITCH_PROVIDER_REPO) { $env:SWITCH_PROVIDER_REPO } else { "danubiolagoa/switch-provider" }
$ApiUrl = "https://api.github.com/repos/$Repo/releases/latest"

Write-Host "Buscando ultima release de $Repo..."
$Release = Invoke-RestMethod -Uri $ApiUrl -Headers @{ "User-Agent" = "switch-provider-installer" }

$Asset = $Release.assets |
    Where-Object { $_.name -match 'x64.*setup\.exe$|setup\.exe$' } |
    Select-Object -First 1

if (-not $Asset) {
    throw "Nenhum instalador Windows .exe encontrado na ultima release."
}

$Installer = Join-Path $env:TEMP $Asset.name
Write-Host "Baixando $($Asset.name)..."
Invoke-WebRequest -Uri $Asset.browser_download_url -OutFile $Installer

Write-Host "Abrindo instalador grafico..."
Start-Process -FilePath $Installer -Wait

Write-Host "Instalacao concluida."
