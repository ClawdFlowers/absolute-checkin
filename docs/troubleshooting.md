# Troubleshooting

## Common issues

### Script loops without detecting success
Possible causes:
- `AbtPS.exe -l` output text does not exactly match expected values
- status is being checked too soon
- utility output format changed

What to do:
- run `AbtPS.exe -l` manually in the SDK folder
- copy the exact output
- update the script's status matching logic

---

### SDK folder does not copy
Possible causes:
- source path is wrong
- source drive is missing
- permissions issue

What to do:
- confirm the configured source path exists
- confirm the machine can access the source
- test manual copy first

---

### Admin prompt does not appear
Possible causes:
- PowerShell launch method is wrong
- execution is being blocked by policy
- UAC behavior differs on the machine

What to do:
- run PowerShell manually as Administrator
- launch the script directly from elevated PowerShell

---

### CMD window does not open correctly
Possible causes:
- launcher or script was modified
- path quoting issue
- Windows shell behavior differs on the machine

What to do:
- verify the script uses `cmd.exe`
- test opening `cmd.exe` manually in the target directory

---

### Check-in fails repeatedly
Possible causes:
- network issue
- Absolute service issue
- local agent issue on the machine

What to do:
- retry manually with `AbtPS.exe -c`
- check status with `AbtPS.exe -l`
- confirm the machine has connectivity
- escalate if the Absolute agent itself is failing
