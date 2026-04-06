# Absolute Check-In Automation

A small Windows automation project for running the Absolute inventory check-in process with less manual work.

## What this does

This project automates the repetitive parts of checking a Windows computer into the Absolute inventory system.

The PowerShell script:

- runs with Administrator privileges
- copies the required Absolute SDK files locally if needed
- runs the `AbtPS.exe -c` check-in command
- waits before checking status
- polls `AbtPS.exe -l` for status updates
- retries automatically if the call fails
- opens a secondary `cmd.exe` window in the SDK folder for manual checks
- leaves the SDK files on the machine for future monthly check-ins

## Current version

See `version.json`.

## Project files

- `Check-In-Absolute.ps1` — main automation script
- `Launch-Check-In.bat` — launcher for easier execution
- `version.json` — current project version
- `docs/troubleshooting.md` — notes for diagnosing common issues

## Requirements

- Windows
- PowerShell 5.1 or later
- Administrator credentials
- Access to the required Absolute SDK files
- `AbtPS.exe` must work when run from its local folder

## Current workflow assumptions

This script currently assumes:

- the Absolute SDK source folder is available locally or from a known source
- `AbtPS.exe` must be run from the directory where it exists
- `AbtPS.exe -l` returns status text similar to:
  - `Last call succeeded`
  - `Last call failed`
  - `Agent is calling`

If the utility output changes, the status parsing in the script may need to be updated.

## Usage

Run the PowerShell script directly:

```powershell
powershell.exe -ExecutionPolicy Bypass -File .\Check-In-Absolute.ps1
```

Or use the batch launcher:

```bat
Launch-Check-In.bat
```

## Versioning

This project uses a simple manual version number stored in:

- `version.json`
- and optionally in the PowerShell script itself

Current starting version: `0.5`

Planned future improvements:

- launcher checks local vs repo version
- self-updating script download
- centralized resource download from GitHub
- improved logging
- better troubleshooting output

## Notes

This project is intended to stay small, practical, and maintainable.

The goal is not to build a giant software platform. The goal is to save time and reduce repetitive manual steps during monthly Absolute check-ins.

## AI Disclosure
This project utilized AI in it's coding process, but does not utilize AI tools when making calls or in it's execution.
