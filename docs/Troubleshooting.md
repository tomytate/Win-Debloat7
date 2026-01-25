# Troubleshooting & FAQ

## Common Issues

### "Operation Canceled" or "Access Denied" on WaaSMedicSvc
*   **Cause**: You tried to stop a protected Windows service.
*   **Fix**: This is normal behavior. Win-Debloat7 handles this error gracefully in logs. Rebooting usually forces the service into the disabled state if registry keys were set.

### "PowerShell 7.5 required"
*   **Cause**: You are running in the legacy Windows PowerShell 5.1 (blue icon).
*   **Fix**: Install PowerShell 7 (black icon) from the [Microsoft Store](https://apps.microsoft.com/detail/9mz1sn7389xv) or GitHub.

### "Extras ZIP flagged as virus"
*   **Cause**: The Extras edition contains **Defender Remover** and **MAS**, which are "HackTools".
*   **Fix**: Pause Real-time protection to run the tool. **Use the Standard Edition if you do not strictly need these tools.**

---

## How to Restore

If a tweak broke something (e.g., Xbox Login):

1.  Open Win-Debloat7 GUI.
2.  Go to the **Restore / Snapshots** tab.
3.  Select the snapshot created *before* you applied the tweak.
4.  Click **Restore System**.
5.  Reboot.

## 📝 Logs

All actions are logged for auditing purposes.
*   **Location**: `C:\ProgramData\Win-Debloat7\Logs`
*   **Format**: `.log` (Text files with timestamps)

Attach the latest log file when [reporting an issue](https://github.com/tomytate/Win-Debloat7/issues).
