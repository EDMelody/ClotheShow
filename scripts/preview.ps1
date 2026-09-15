$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$address = Get-NetIPAddress -AddressFamily IPv4 | Where-Object {
    $_.IPAddress -notlike '127.*' -and $_.IPAddress -notlike '169.254.*' -and $_.PrefixOrigin -ne 'WellKnown'
} | Select-Object -First 1 -ExpandProperty IPAddress
if (-not $address) { $address = 'localhost' }
Write-Output "童裳体验版：http://${address}:8080"
Write-Output '保持此窗口开启；按 Ctrl+C 停止。'
node (Join-Path $PSScriptRoot 'serve-demo.mjs')
