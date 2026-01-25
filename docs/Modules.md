# Modules Reference

Win-Debloat7 is built on a modular architecture. Each feature is encapsulated in a standalone PowerShell Module (`.psm1`) located in `src/modules`.

## 🧩 Core Modules

### **Bloatware (`src/modules/Bloatware`)**
Responsible for identifying and removing Appx packages.
- **Key Function:** `Remove-WinDebloat7Bloatware`
- **Logic:** Uses an internal database of package families mapped to "Conservative", "Moderate", and "Aggressive" tiers.
- **Safety:** Always checks the `exclude_list` from your profile before removal.

### **Privacy (`src/modules/Privacy`)**
Hardens system privacy via Registry and Group Policy.
- **Key Function:** `Set-WinDebloat7Privacy`
- **Features:** 
    - Disables DiagTrack (Connected User Experiences).
    - Blocks specific telemetry domains via `hosts` file.
    - Disables Windows 11 Copilot and Recall features.

### **Performance (`src/modules/Performance`)**
Tunes system responsiveness.
- **Key Function:** `Set-WinDebloat7Performance`
- **Features:**
    - **Power Plan:** Unlocks and applies "Ultimate Performance".
    - **Ram:** Optimizes memory management priorities.
    - **Gaming:** Disables Nagle's algorithm (TCPNoDelay) for lower latency.

### **Software (`src/modules/Software`)**
Package manager wrapper.
- **Key Function:** `Install-WinDebloat7Essentials`
- **Logic:** Detects `winget` or `chocolatey`. Installs common apps (Browser, 7-Zip, Notepad++) if requested.

### **Extras (`src/modules/Extras`)**
*Available in Extras Edition only.*
- **Key Function:** `Invoke-WinDebloat7DefenderRemover`
- **Purpose:** Downloads advanced tools that are often flagged by AV.

## ⚙️ Core Infrastructure (`src/core`)

These modules power the framework itself:

- **`Config.psm1`**: YAML parser and validation logic.
- **`Logger.psm1`**: Thread-safe logging with rotation and color output.
- **`Registry.psm1`**: Helper functions for safe registry modification (Set-HKCU, Set-HKLM).
- **`State.psm1`**: Manages Snapshots (CliXml encryption) and Restore logic.

## 🖼️ UI (`src/ui`)

- **`GUI.psm1`**: Handling logic for the WPF Dashboard.
- **`Menu.psm1`**: The interactive CLI menu system.
- **`MainWindow.xaml`**: The visual layout definition.
