# Absolute Check-In Automation

A small Windows automation project for running the Absolute inventory check-in process with less manual work.

## What this does

This project automates the repetitive parts of checking a Windows computer into the Absolute inventory system.

The PowerShell script:

- **self-installs** to `C:\ProgramData\AbsoluteCheckIn\`
- **checks GitHub** for updates and auto-updates itself if a newer version is available
- **validates** that the required Absolute SDK files are present
- **prompts clearly** if the SDK is missing, with instructions on where to place it
- runs the `AbtPS.exe -c` check-in command
- waits before checking status
- polls `AbtPS.exe -l` for status updates
- retries automatically if the call fails
- opens a secondary `cmd.exe` window in the SDK folder for manual checks
- leaves the SDK files on the machine for future monthly check-ins

## Current version

See `version.json`.

## Project files

- `Check-In-Absolute.ps1` — main automation script (self-installs, self-updates, runs check-in)
- `Launch-Check-In.bat` — launcher for easier execution
- `version.json` — current project version
- `docs/troubleshooting.md` — notes for diagnosing common issues

## Requirements

- Windows
- PowerShell 5.1 or later
- Administrator credentials
- Access to the required Absolute SDK files (`AbtPS_SDK_1.3`)
- Internet access (for version checking and self-updates)
- `AbtPS.exe` must work when run from its local folder

## First-time setup

### Step 1: Download and run the launcher

Extract the release ZIP anywhere on the computer and run:

```bat
Launch-Check-In.bat
```

The script will automatically install itself to:

```
C:\ProgramData\AbsoluteCheckIn\
```

### Step 2: Provide the Absolute SDK

If the script reports that `AbtPS_SDK_1.3` is missing, obtain the folder from your IT department or supervisor and copy the **entire folder** to:

```
C:\ProgramData\AbsoluteCheckIn\AbtPS_SDK_1.3\
```

Then re-run the script.

### Step 3: Done

The script is now installed and the SDK is in place. On future runs it will:
- check GitHub for updates
- run the check-in automatically

## Monthly usage (after first setup)

After the first setup, simply run the installed launcher:

```bat
C:\ProgramData\AbsoluteCheckIn\Launch-Check-In.bat
```

Or double-click it from File Explorer.

The script will:
1. Check for updates from GitHub
2. Update itself automatically if a newer version exists
3. Run the check-in process

## Current workflow assumptions

- `AbtPS.exe` must be run from the directory where it exists
- `AbtPS.exe -l` returns status text similar to:
  - `Last call succeeded`
  - `Last call failed`
  - `Agent is calling`

If the utility output changes, the status parsing in the script may need to be updated.

## Versioning

This project uses a simple version number stored in:

- `version.json` in the GitHub repo
- displayed at runtime by both the launcher and the PowerShell script
- checked automatically on every run against the GitHub `main` branch

## Planned future improvements

- improved logging
- silent mode for automated deployment
- better error handling for offline environments

## Notes

This project is intended to stay small, practical, and maintainable.

The goal is not to build a giant software platform. The goal is to save time and reduce repetitive manual steps during monthly Absolute check-ins.

**The `AbtPS_SDK_1.3` folder is proprietary software and is NOT included in this repository.** You must obtain it separately from your IT department or Absolute representative.
