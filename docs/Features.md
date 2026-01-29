# Features & Capabilities

Win-Debloat7 is modular. You can run the entire suite using a Profile, or use individual modules via the CLI/GUI.

## 🖥️ Graphical User Interface (GUI)

Launch interactive mode with `.\Win-Debloat7.exe` -> Option 2.

### Tools Tab
A command center for quick actions:
*   **Update Drivers**: Queries version catalogs (Winget/SDIO) to update system drivers.
*   **Repair System**: Runs `sfc /scannow` and `DISM` restoration in one click.
*   **Network Reset**: Flushes DNS, releases IP, and resets Winsock (fixes connection drops).
*   **Reset Update**: Clears the `SoftwareDistribution` folder to fix stuck Windows Updates.

### Telemetry Monitor
The dashboard shows a live counter of blocked connection attempts to known telemetry servers (e.g., `v10.events.data.microsoft.com`).

---

## 🛠️ Core Modules

### 1. Bloatware Removal
Removes pre-installed Appx packages.
*   **Modes**: 
    *   *Conservative*: Removes only promo apps (Candy Crush, Disney+).
    *   *Moderate*: Removes non-essential apps (Solitaire, Skype, tips).
    *   *Aggressive*: Removes everything except Store and Calculator.
*   **Exclusions**: You can whitelist apps in your profile config.

### 2. Privacy Hardening
*   **Telemetry**: Disables "Connected User Experiences", "DiagTrack", and "WaaSMedicSvc".
*   **Advertising**: Resets Advertising ID and disables Start Menu "suggestions".
*   **Co-Pilot / Recall**: Completely disables AI integration features via Group Policy.

### 3. Performance Tweaks
*   **Power Plan**: Unlocks "Ultimate Performance" mode.
*   **RAM Optimization**: Reduces non-paged pool usage.
*   **Gaming Mode**: 
    *   Disables Nagle's Algorithm (SystemResponsiveness).
    *   Prioritizes GPU tasks.
    *   Disables Game DVR/Bar background recording.

### 4. System Maintenance
*   **Deep Clean**: Runs `cleanmgr.exe` with all flags (777) enabled.
*   **Component Cleanup**: Compresses the WinSxS folder using `DISM /StartComponentCleanup`.

### 5. Software & Driver Manager
*   **Winget Integration**: Install and *Update* (`--all`) applications.
*   **Essentials**: One-click install for Chrome, Firefox, Steam, Discord, 7Zip.
*   **Driver Updates**: Update GPU drivers (NVIDIA/AMD) or use SDIO for broad hardware support.

---

## 🛡️ Snapshots (Safety)

Before *any* change, the system creates a specialized lightweight restore point.
*   **Encryption**: Snapshot metadata is encrypted using Windows DPAPI.
*   **Portable**: Snapshots are stored in `ProgramData\Win-Debloat7\Snapshots`.
*   **Restoration**: You can undo changes instantaneously via the "Restore" tab in the GUI.
