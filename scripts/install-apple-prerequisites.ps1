[CmdletBinding()]
param(
    [string]$ITunesRoot = 'E:\iTunes',
    [string]$ICloudRoot = 'E:\iCloud'
)

$ErrorActionPreference = 'Stop'
$principal = [Security.Principal.WindowsPrincipal]::new([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    throw 'This installer must run as Administrator.'
}

$itunesInstaller = Join-Path $ITunesRoot 'Installer'
$icloudInstaller = Join-Path $ICloudRoot 'Installer'
$logDirectory = Join-Path $ICloudRoot 'InstallLogs'
New-Item -ItemType Directory -Force -Path $logDirectory | Out-Null

$packages = @(
    @{ Name = 'Apple Application Support 64-bit'; Msi = Join-Path $icloudInstaller 'AppleApplicationSupport64.msi'; Properties = @("INSTALLDIR=$ICloudRoot\Apple Application Support (64-bit)") },
    @{ Name = 'Bonjour 64-bit'; Msi = Join-Path $icloudInstaller 'Bonjour64.msi'; Properties = @("INSTALLDIR=$ICloudRoot\Bonjour", "INSTALLDIR64=$ICloudRoot\Bonjour") },
    @{ Name = 'Apple Software Update'; Msi = Join-Path $icloudInstaller 'AppleSoftwareUpdate.msi'; Properties = @("INSTALLDIR=$ICloudRoot\Apple Software Update") },
    @{ Name = 'Apple Mobile Device Support'; Msi = Join-Path $itunesInstaller 'AppleMobileDeviceSupport64.msi'; Properties = @("INSTALLDIR=$ITunesRoot\Mobile Device Support", "INSTALLDIR32=$ITunesRoot\Mobile Device Support (32-bit)") },
    @{ Name = 'iTunes'; Msi = Join-Path $itunesInstaller 'iTunes64.msi'; Properties = @("INSTALLDIR=$ITunesRoot\iTunes") },
    @{ Name = 'iCloud'; Msi = Join-Path $icloudInstaller 'iCloud64.msi'; Properties = @("INSTALLDIR=$ICloudRoot\iCloud") }
)

$results = @()
foreach ($package in $packages) {
    if (-not (Test-Path -LiteralPath $package.Msi -PathType Leaf)) {
        throw "Missing signed Apple package: $($package.Msi)"
    }
    $signature = Get-AuthenticodeSignature -LiteralPath $package.Msi
    if ($signature.Status -ne 'Valid' -or $signature.SignerCertificate.Subject -notmatch 'CN=Apple Inc\.') {
        throw "Apple signature validation failed: $($package.Msi)"
    }
    $safeName = $package.Name -replace '[^A-Za-z0-9]+', '-'
    $log = Join-Path $logDirectory "$safeName.log"
    $arguments = @('/i', $package.Msi) + $package.Properties + @('IAcceptLicense=Yes', '/qn', '/norestart', '/L*v', $log)
    $process = Start-Process -FilePath 'msiexec.exe' -ArgumentList $arguments -Wait -PassThru -WindowStyle Hidden
    $result = [PSCustomObject]@{ Component = $package.Name; ExitCode = $process.ExitCode; Log = $log }
    $results += $result
    $results | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $logDirectory 'summary.json') -Encoding UTF8
    if ($process.ExitCode -notin @(0, 1638, 3010)) {
        throw "Installation failed: $($package.Name), exit code $($process.ExitCode). See $log"
    }
}

$results | Format-Table -AutoSize
