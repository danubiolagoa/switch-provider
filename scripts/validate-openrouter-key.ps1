param(
    [Parameter(Mandatory = $true)]
    [string]$InputFile
)

$ErrorActionPreference = 'Stop'
$json = Get-Content -Raw -LiteralPath $InputFile | ConvertFrom-Json

if ($json.data) {
    exit 0
}

$msg = $null
if ($json.error) {
    if ($json.error.message) {
        $msg = [string]$json.error.message
    } else {
        $msg = [string]$json.error
    }
}
if (-not $msg) {
    $msg = "Authentication failed."
}

Write-Output $msg
exit 1
