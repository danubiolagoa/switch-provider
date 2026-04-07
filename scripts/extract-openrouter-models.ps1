param(
    [Parameter(Mandatory = $true)]
    [string]$InputFile,
    [Parameter(Mandatory = $true)]
    [string]$OutputFile
)

$ErrorActionPreference = 'Stop'
$json = Get-Content -Raw -LiteralPath $InputFile | ConvertFrom-Json

if (-not $json.data) {
    throw "Response does not contain a data array."
}

$json.data | ForEach-Object { $_.id } | Set-Content -LiteralPath $OutputFile -Encoding ascii
