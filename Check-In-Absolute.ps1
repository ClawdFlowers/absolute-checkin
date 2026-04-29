#requires -Version 5.1

<#
    Absolute Check-In Helper
    Version: 0.7.1

    What it does:
    - Installs to ProgramData if running from elsewhere
    - Checks GitHub for latest version and self-updates
    - Validates AbtPS_SDK_1.3 exists locally
    - Runs AbtPS.exe -c to start the check-in
    - Waits 30 seconds before the first status check
    - Polls AbtPS.exe -l every 30 seconds
    - Retries automatically up to 3 times if the call fails
    - Opens a secondary CMD window in the correct folder for manual checks
    - Leaves the copied files on the machine for future monthly use
#>

param(
    [string]$InstallPath = "$env:ProgramData\AbsoluteCheckIn",
    [string]$GitHubRepo = "ClawdFlowers/absolute-checkin",
    [int]$MaxRetries = 3,
    [int]$InitialWaitSeconds = 30,
    [int]$PollSeconds = 30
)

$ScriptVersion = "0.7.1"
$ErrorActionPreference = "Stop"

function Write-Info($msg) {
    Write-Host "[INFO]  $msg" -ForegroundColor Cyan
}

function Write-Good($msg) {
    Write-Host "[OK]    $msg" -ForegroundColor Green
}

function Write-WarnMsg($msg) {
    Write-Host "[WARN]  $msg" -ForegroundColor Yellow
}

function Write-Bad($msg) {
    Write-Host "[FAIL]  $msg" -ForegroundColor Red
}

# Display version info at startup
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  Absolute Check-In Helper" -ForegroundColor Cyan
Write-Host "  Version: $ScriptVersion" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# ==========================================
# Install / Self-Update Section
# ==========================================

function Get-LocalVersion {
    $versionFile = Join-Path $InstallPath "version.json"
    if (Test-Path $versionFile) {
        $content = Get-Content $versionFile -Raw | ConvertFrom-Json
        return $content.version
    }
    return "0.0.0"
}

function Get-RemoteVersion {
    try {
        $url = "https://raw.githubusercontent.com/$GitHubRepo/main/version.json"
        $response = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 10
        $content = $response.Content | ConvertFrom-Json
        return $content.version
    } catch {
        Write-WarnMsg "Could not reach GitHub for version check"
        return $null
    }
}

function Compare-Versions {
    param([string]$Local, [string]$Remote)
    try {
        $localVer = [System.Version]$Local
        $remoteVer = [System.Version]$Remote
        return $remoteVer.CompareTo($localVer)
    } catch {
        return $Remote.CompareTo($Local)
    }
}

function Install-ToProgramData {
    if (-not (Test-Path $InstallPath)) {
        Write-Info "Creating install directory: $InstallPath"
        New-Item -ItemType Directory -Path $InstallPath -Force | Out-Null
    }

    $scriptName = Split-Path $PSCommandPath -Leaf
    $batName = "Launch-Check-In.bat"
    $sourceDir = Split-Path $PSCommandPath -Parent

    $destScript = Join-Path $InstallPath $scriptName
    if ($PSCommandPath -ne $destScript) {
        Write-Info "Installing script to $InstallPath..."
        Copy-Item -Path $PSCommandPath -Destination $destScript -Force
    }

    $sourceBat = Join-Path $sourceDir $batName
    $destBat = Join-Path $InstallPath $batName
    if ((Test-Path $sourceBat) -and ($sourceBat -ne $destBat)) {
        Write-Info "Installing launcher to $InstallPath..."
        Copy-Item -Path $sourceBat -Destination $destBat -Force
    }

    $versionFile = Join-Path $InstallPath "version.json"
    if (-not (Test-Path $versionFile)) {
        @{ version = $ScriptVersion } | ConvertTo-Json | Set-Content $versionFile
    }
}

function Update-FromGitHub {
    param([string]$TargetVersion)

    $zipUrl = "https://github.com/$GitHubRepo/releases/download/v$TargetVersion/absolute-checkin-v$TargetVersion.zip"
    $tempZip = Join-Path $env:TEMP "absolute-checkin-v$TargetVersion.zip"
    $tempExtract = Join-Path $env:TEMP "absolute-checkin-v$TargetVersion"

    try {
        Write-Info "Downloading v$TargetVersion from GitHub..."
        Invoke-WebRequest -Uri $zipUrl -OutFile $tempZip -UseBasicParsing -TimeoutSec 60

        Write-Info "Extracting update..."
        if (Test-Path $tempExtract) {
            Remove-Item $tempExtract -Recurse -Force
        }
        Expand-Archive -Path $tempZip -DestinationPath $tempExtract -Force

        Write-Info "Updating files in $InstallPath..."
        Get-ChildItem -Path $tempExtract | Where-Object { $_.Name -ne '.git' } | ForEach-Object {
            $dest = Join-Path $InstallPath $_.Name
            if ($_.PSIsContainer) {
                Copy-Item -Path $_.FullName -Destination $dest -Recurse -Force
            } else {
                Copy-Item -Path $_.FullName -Destination $dest -Force
            }
        }

        Remove-Item $tempZip -Force -ErrorAction SilentlyContinue
        Remove-Item $tempExtract -Recurse -Force -ErrorAction SilentlyContinue

        Write-Good "Updated to v$TargetVersion"

        $updatedScript = Join-Path $InstallPath "Check-In-Absolute.ps1"
        Write-Info "Relaunching updated script..."
        Start-Process powershell.exe -ArgumentList "-ExecutionPolicy Bypass -File `"$updatedScript`""
        exit
    } catch {
        Write-Bad "Update failed: $_"
        Write-WarnMsg "Continuing with current version..."
    }
}

# Step 1: Ensure installed to ProgramData
Install-ToProgramData

# Step 2: Relaunch from install path if needed
$installedScript = Join-Path $InstallPath (Split-Path $PSCommandPath -Leaf)
if ($PSCommandPath -ne $installedScript) {
    Write-Info "Relaunching from installed location..."
    Start-Process powershell.exe -ArgumentList "-ExecutionPolicy Bypass -File `"$installedScript`""
    exit
}

# Step 3: Check for updates
$localVersion = Get-LocalVersion
$remoteVersion = Get-RemoteVersion

if ($remoteVersion) {
    $comparison = Compare-Versions -Local $localVersion -Remote $remoteVersion
    if ($comparison -gt 0) {
        Write-Info "Update available: v$localVersion -> v$remoteVersion"
        Update-FromGitHub -TargetVersion $remoteVersion
    } else {
        Write-Info "Running latest version (v$localVersion)"
    }
} else {
    Write-WarnMsg "Skipping version check — using v$localVersion"
}

# ==========================================
# SDK Validation Section
# ==========================================

$localSdk = Join-Path $InstallPath "AbtPS_SDK_1.3"
$exePath = Join-Path $localSdk "AbtPS.exe"

if (-not (Test-Path $exePath)) {
    Write-Bad "AbtPS_SDK_1.3 not found!"
    Write-Host ""
    Write-Host "Required files are missing. Please do the following:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  1. Obtain the AbtPS_SDK_1.3 folder from your IT department or supervisor" -ForegroundColor Yellow
    Write-Host "  2. Copy the entire AbtPS_SDK_1.3 folder to:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "     $InstallPath" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  3. Re-run this script" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "The script will then proceed with the check-in process." -ForegroundColor Yellow
    Write-Host ""
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Good "AbtPS_SDK_1.3 found at $localSdk"

$workingDir = Split-Path $exePath -Parent

# ==========================================
# Check-In Logic
# ==========================================

Set-Location $workingDir
Write-Info "Working directory set to: $workingDir"

function Invoke-Abt {
    param(
        [string]$ExePath,
        [string]$Argument
    )

    Write-Info "Running: AbtPS.exe $Argument"
    $output = & $ExePath $Argument 2>&1 | Out-String

    if ($output) {
        Write-Host $output.Trim()
    }

    return $output
}

function Get-AbtStatus {
    param(
        [string]$ExePath
    )

    $output = (Invoke-Abt -ExePath $ExePath -Argument "-l" | Out-String).Trim()

    if ($output -match "(?i)last call succeeded") {
        return "Success"
    }
    elseif ($output -match "(?i)last call failed") {
        return "Failed"
    }
    elseif ($output -match "(?i)agent is calling|currently calling|call in progress|\bcalling\b") {
        return "InProgress"
    }
    else {
        Write-WarnMsg "Raw status output: $output"
        return "Unknown"
    }
}

function Open-StatusWindow {
    param(
        [string]$ExePath
    )

    $workingDir = Split-Path $ExePath -Parent
    $cmdArgs = '/k echo Absolute status window opened. & echo. & AbtPS.exe -l & echo. & echo Run AbtPS.exe -l manually anytime.'

    Start-Process -FilePath "$env:SystemRoot\System32\cmd.exe" -ArgumentList $cmdArgs -WorkingDirectory $workingDir
}

Write-Info "Opening a secondary CMD status window..."
Open-StatusWindow -ExePath $exePath

$attempt = 0

while ($attempt -lt $MaxRetries) {
    $attempt++
    Write-Info "Starting check-in attempt $attempt of $MaxRetries..."

    Invoke-Abt -ExePath $exePath -Argument "-c" | Out-Null

    Write-Info "Waiting $InitialWaitSeconds seconds before first status check..."
    Start-Sleep -Seconds $InitialWaitSeconds

    while ($true) {
        $status = Get-AbtStatus -ExePath $exePath

        switch ($status) {
            "Success" {
                Write-Good "Check-in succeeded on attempt $attempt."
                Write-Host ""
                Write-Host "Done. SDK folder has been left in place at:" -ForegroundColor Green
                Write-Host "  $localSdk" -ForegroundColor Green
                Read-Host "Press Enter to exit"
                exit 0
            }

            "Failed" {
                Write-WarnMsg "Check-in failed on attempt $attempt."
                break
            }

            "InProgress" {
                Write-Info "Check-in still in progress..."
            }

            "Unknown" {
                Write-WarnMsg "Status did not match expected success/failure yet. Checking again..."
            }
        }

        Start-Sleep -Seconds $PollSeconds
    }

    if ($attempt -lt $MaxRetries) {
        Write-Info "Retrying check-in in 5 seconds..."
        Start-Sleep -Seconds 5
    }
}

Write-Bad "All $MaxRetries attempts failed."
Write-Host ""
Write-Host "You can manually inspect status from this folder:" -ForegroundColor Yellow
Write-Host "  $workingDir" -ForegroundColor Yellow
Write-Host ""
Write-Host "Manual command:" -ForegroundColor Yellow
Write-Host "  .\AbtPS.exe -l" -ForegroundColor Yellow

Read-Host "Press Enter to exit"
exit 1
