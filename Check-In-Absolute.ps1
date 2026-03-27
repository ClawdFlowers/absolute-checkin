#requires -Version 5.1

<#
    Absolute check-in helper
    Version: 0.5

    What it does:
    - Ensures the script is running as Administrator
    - Copies the entire AbtPS_SDK_1.3 folder locally if it is missing
    - Runs AbtPS.exe -c to start the check-in
    - Waits 60 seconds before the first status check
    - Polls AbtPS.exe -l every 60 seconds to monitor status
    - Retries automatically up to 3 times if the call fails
    - Opens a secondary CMD window in the correct folder for manual checks
    - Leaves the copied files on the machine for future monthly use
    - Does NOT close windows automatically
#>

$ScriptVersion = "0.5"

param(
    [string]$SourceFolder = "D:\AbtPS_SDK_1.3",
    [string]$LocalParentFolder = "$env:ProgramData",
    [int]$MaxRetries = 3,
    [int]$InitialWaitSeconds = 60,
    [int]$PollSeconds = 60
)

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

function Test-IsAdmin {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Ensure-Admin {
    if (-not (Test-IsAdmin)) {
        Write-Info "Not running as Administrator. Relaunching with elevation..."

        $argList = @(
            "-ExecutionPolicy", "Bypass",
            "-File", "`"$PSCommandPath`"",
            "-SourceFolder", "`"$SourceFolder`"",
            "-LocalParentFolder", "`"$LocalParentFolder`"",
            "-MaxRetries", $MaxRetries,
            "-InitialWaitSeconds", $InitialWaitSeconds,
            "-PollSeconds", $PollSeconds
        )

        Start-Process powershell.exe -Verb RunAs -ArgumentList $argList
        exit
    }
}

function Ensure-LocalSdk {
    if (-not (Test-Path $SourceFolder)) {
        throw "Source folder not found: $SourceFolder"
    }

    $folderName = Split-Path $SourceFolder -Leaf
    $localFolder = Join-Path $LocalParentFolder $folderName

    if (-not (Test-Path $localFolder)) {
        Write-Info "Local SDK folder not found. Copying entire folder from source..."
        Copy-Item -Path $SourceFolder -Destination $LocalParentFolder -Recurse -Force
        Write-Good "Copied SDK folder to $localFolder"
    }
    else {
        Write-Info "SDK folder already exists locally: $localFolder"
    }

    $localExe = Join-Path $localFolder "AbtPS.exe"

    if (-not (Test-Path $localExe)) {
        throw "AbtPS.exe not found in local SDK folder: $localExe"
    }

    return $localExe
}

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
    $cmdArgs = "/k cd /d `"$workingDir`" && echo Absolute status window opened. && echo. && AbtPS.exe -l && echo. && echo Run AbtPS.exe -l manually anytime."

    Start-Process -FilePath "$env:SystemRoot\System32\cmd.exe" -ArgumentList $cmdArgs -WorkingDirectory $workingDir
}

Ensure-Admin

$exePath = Ensure-LocalSdk
$workingDir = Split-Path $exePath -Parent

Set-Location $workingDir
Write-Info "Working directory set to: $workingDir"

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
                Write-Host "  $(Split-Path $exePath -Parent)" -ForegroundColor Green
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
Write-Host ""
Write-Host "SDK folder was left in place for future use." -ForegroundColor Yellow

Read-Host "Press Enter to exit"
exit 1
