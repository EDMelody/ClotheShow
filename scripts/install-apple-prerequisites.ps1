[CmdletBinding()]
param(
    [string]$ITunesRoot = 'E:\iTunes',
    [string]$ICloudRoot = 'E:\iCloud'
)

$ErrorActionPreference = 'Stop'

function ConvertTo-MsiArgument {
    param([Parameter(Mandatory)][string]$Value)

    if ($Value -match '^(?<name>[^=\s]+)=(?<data>.*)$') {
        return '{0}="{1}"' -f $Matches.name, ($Matches.data -replace '"', '\"')
    }
    return '"{0}"' -f ($Value -replace '"', '\"')
}

$principal = [Security.Principal.WindowsPrincipal]::new([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    throw 'This installer must run as Administrator.'
}

$itunesInstaller = Join-Path $ITunesRoot 'Installer'
$icloudInstaller = Join-Path $ICloudRoot 'Installer'
$logDirectory = Join-Path $ICloudRoot 'InstallLogs'
New-Item -ItemType Directory -Force -Path $logDirectory | Out-Null

$packages = @(
    @{ Name = 'Apple Application Support 32-bit'; Msi = Join-Path $icloudInstaller 'AppleApplicationSupport.msi'; Properties = @("INSTALLDIR=$ICloudRoot\Apple Application Support (32-bit)") },
    @{ Name = 'Apple Application Support 64-bit'; Msi = Join-Path $icloudInstaller 'AppleApplicationSupport64.msi'; Properties = @("INSTALLDIR=$ICloudRoot\Apple Application Support (64-bit)") },
    @{ Name = 'Bonjour 32-bit'; Msi = Join-Path $icloudInstaller 'Bonjour.msi'; Properties = @("INSTALLDIR=$ICloudRoot\Bonjour (32-bit)") },
    @{ Name = 'Bonjour 64-bit'; Msi = Join-Path $icloudInstaller 'Bonjour64.msi'; Properties = @("INSTALLDIR=$ICloudRoot\Bonjour", "INSTALLDIR64=$ICloudRoot\Bonjour") },
    @{ Name = 'Apple Software Update'; Msi = Join-Path $icloudInstaller 'AppleSoftwareUpdate.msi'; Properties = @("INSTALLDIR=$ICloudRoot\Apple Software Update") },
    @{ Name = 'Apple Mobile Device Support'; Msi = Join-Path $itunesInstaller 'AppleMobileDeviceSupport64.msi'; Properties = @("INSTALLDIR=$ITunesRoot\Mobile Device Support", "INSTALLDIR32=$ITunesRoot\Mobile Device Support (32-bit)") },
    @{ Name = 'iTunes'; Msi = Join-Path $itunesInstaller 'iTunes64.msi'; Properties = @("INSTALLDIR=$ITunesRoot\iTunes") },
    @{ Name = 'iCloud'; Msi = Join-Path $icloudInstaller 'iCloud64.msi'; Properties = @("INSTALLDIR=$ICloudRoot\iCloud") }
)

$results = @()
foreach ($package in $packages) {
    Write-Host "Checking Apple signature: $($package.Name)..."
    if (-not (Test-Path -LiteralPath $package.Msi -PathType Leaf)) {
        throw "Missing signed Apple package: $($package.Msi)"
    }
    $signature = Get-AuthenticodeSignature -LiteralPath $package.Msi
    if ($signature.Status -ne 'Valid' -or $signature.SignerCertificate.Subject -notmatch 'CN=Apple Inc\.') {
        throw "Apple signature validation failed: $($package.Msi)"
    }
    $safeName = $package.Name -replace '[^A-Za-z0-9]+', '-'
    $log = Join-Path $logDirectory "$safeName.log"
    $arguments = @('/i', (ConvertTo-MsiArgument $package.Msi))
    $arguments += $package.Properties | ForEach-Object { ConvertTo-MsiArgument $_ }
    $arguments += @('IAcceptLicense=Yes', '/qn', '/norestart', '/L*v', (ConvertTo-MsiArgument $log))
    Write-Host "Installing $($package.Name)..."
    $process = Start-Process -FilePath 'msiexec.exe' -ArgumentList ($arguments -join ' ') -Wait -PassThru
    $result = [PSCustomObject]@{ Component = $package.Name; ExitCode = $process.ExitCode; Log = $log }
    $results += $result
    $results | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $logDirectory 'summary.json') -Encoding UTF8
    if ($process.ExitCode -notin @(0, 1638, 3010)) {
        $pendingRename = Get-ItemProperty -LiteralPath 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager' -Name PendingFileRenameOperations -ErrorAction SilentlyContinue
        if ($package.Name -eq 'iCloud' -and $process.ExitCode -eq 1603 -and $null -ne $pendingRename) {
            throw "Installation failed: iCloud, exit code 1603. Windows has pending file operations; restart Windows and run this installer again. See $log"
        }
        throw "Installation failed: $($package.Name), exit code $($process.ExitCode). See $log"
    }
    Write-Host "Completed $($package.Name) (exit code $($process.ExitCode))."
}

$results | Format-Table -AutoSize
