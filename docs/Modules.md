# Modules Reference

Win-Debloat7 is built on a modular architecture. Each feature is encapsulated in a standalone PowerShell Module (`.psm1`) located in `src/modules`. The manifest registers **28 modules** exporting **92 functions**.

## 🧩 Feature Modules

### **Bloatware** (`src/modules/Bloatware`)
Identifies and removes pre-installed Appx packages.
- **Key Functions:** `Get-WinDebloat7BloatwareList`, `Remove-WinDebloat7Bloatware`
- **Advanced:** `Uninstall-WinDebloat7OneDrive`, `Uninstall-WinDebloat7Edge`, `Uninstall-WinDebloat7Xbox`
- **Logic:** O(N) regex-based matching against an internal database of 80+ known bloatware packages.

### **Privacy** (`src/modules/Privacy`)
Hardens system privacy via Registry, Group Policy, and Hosts blocking.
- **Key Functions:** `Set-WinDebloat7Privacy`, `Disable-WinDebloat7TelemetryTasks`
- **Hosts Blocking:** `Add-WinDebloat7HostsBlock`, `Get-WinDebloat7TelemetryDomains`
- **Features:** Disables DiagTrack, blocks telemetry domains, disables Copilot/Recall.

### **Performance** (`src/modules/Performance`)
Tunes system responsiveness and power management.
- **Key Functions:** `Set-WinDebloat7Performance`, `Set-WinDebloat7Gaming`
- **Benchmarking:** `Measure-WinDebloat7System`, `Compare-WinDebloat7Benchmarks`
- **Features:** Ultimate Performance power plan, Nagle's algorithm, Game DVR, RAM optimization.

### **Services** (`src/modules/Performance/Services.psm1`)
JSON-driven service optimization with intelligent presets.
- **Key Functions:** `Set-WinDebloat7Services`, `Get-WinDebloat7ServicePresets`
- **Presets:** Privacy, Performance, Security, Minimal
- **Database:** `config/services.json` — fully customizable.

### **Tweaks** (`src/modules/Performance/Tweaks.psm1`)
AI disablement and advanced Windows 11 registry tweaks.
- **Key Functions:** `Disable-WinDebloat7AIRecall`, `Disable-WinDebloat7Copilot`, `Disable-WinDebloat7ClickToDo`
- **AI Suite:** Neutralizes Recall, Copilot, Notepad AI, Paint AI, Edge AI.
- **Ads:** `Disable-WinDebloat7Settings365Ads`, `Disable-WinDebloat7DesktopSpotlight`
- **Power:** `Enable-WinDebloat7UltimatePower`

### **UI Customization** (`src/modules/Tweaks/UI.psm1`)
Visual Windows 11 customization.
- **Key Functions:** `Set-WinDebloat7TaskbarAlignment`, `Set-WinDebloat7ContextMenu`
- **Features:** Taskbar alignment, Classic/Modern context menu, Explorer (hide Gallery/Home), Start Menu.

### **Network** (`src/modules/Network`)
DNS configuration and network diagnostics.
- **Key Functions:** `Set-WinDebloat7DNS`, `Get-WinDebloat7NetworkStatus`
- **DNS Providers:** Cloudflare, Google, Quad9, AdGuard, NextDNS, and Family/Malware variants.
- **Database:** `config/dns.json` — extensible.

### **Software** (`src/modules/Software`)
Package manager wrapper for Winget and Chocolatey.
- **Key Functions:** `Install-WinDebloat7Essentials`, `Update-WinDebloat7Software`
- **Logic:** Auto-detects `winget`, forces `--source winget` for reliability.

### **Drivers** (`src/modules/Drivers`)
System and GPU driver management.
- **Key Functions:** `Update-WinDebloat7Drivers`, `Get-WinDebloat7GPUInfo`
- **Sources:** Windows Update, NVIDIA/AMD vendor drivers (via Winget), SDIO.

### **Repair** (`src/modules/Repair`)
System repair and recovery tools.
- **Key Functions:** `Repair-WinDebloat7System`, `Reset-WinDebloat7Network`, `Reset-WinDebloat7Update`
- **Repair Sequence:** ChkDsk → SFC → DISM → SFC (4-step industrial standard).

### **Maintenance** (`src/modules/Maintenance`)
Automated cleanup scheduling.
- **Key Functions:** `Register-WinDebloat7Maintenance`, `Invoke-WinDebloat7Maintenance`
- **Features:** Disk Cleanup (cleanmgr /777), WinSxS component store compression.

### **Integrations** (`src/modules/Integrations`)
Third-party tool wrappers.
- **Key Functions:** `Invoke-WinDebloat7ShutUp10`, `Invoke-WinDebloat7AdwCleaner`, `Update-WinDebloat7SDIO`
- **Purpose:** Download and execute trusted community tools with hash verification.

### **Extras** (`src/modules/Extras`) ⚠️
*Available in Extras Edition only.*
- **Key Functions:** `Invoke-WinDebloat7DefenderRemover`, `Invoke-WinDebloat7Activation`
- **Purpose:** Downloads advanced tools (Defender Remover, MAS) that are flagged by AV.

### **Windows 11** (`src/modules/Windows11`)
Version detection and 25H2 compatibility.
- **Key Functions:** `Get-WindowsVersionInfo`, `Test-Windows11Version`
- **Features:** Build number → version name mapping (21H2 through 25H2).

---

## ⚙️ Core Infrastructure (`src/core`)

These modules power the framework itself:

| Module | Purpose | Key Functions |
|--------|---------|---------------|
| **Logger** | Thread-safe logging with rotation | `Write-Log`, `Start-WD7Logging` |
| **Config** | YAML profile parser & validator | `Import-WinDebloat7Config`, `Test-WinDebloat7Config` |
| **Registry** | Safe registry modification with hive validation | `Set-RegistryKey`, `Get-RegistryKey`, `Test-RegistryKey` |
| **State** | Snapshot management (DPAPI encryption) | `New-WinDebloat7Snapshot`, `Restore-WinDebloat7Snapshot` |
| **SystemState** | Live system status detection | `Get-WinDebloat7SystemState` |
| **Sysprep** | OEM/Audit mode support | `Test-WinDebloat7Sysprep`, `Mount-WinDebloat7DefaultHive` |

---

## 🖼️ UI Layer (`src/ui`)

| Module | Purpose |
|--------|---------|
| **GUI.psm1** | WPF Dashboard controller (async bloatware scanning, theme toggling) |
| **Menu.psm1** | Interactive TUI menu system with 9 options |
| **Colors.psm1** | TrueColor terminal rendering engine (Cyan/Purple theme) |
| **MainWindow.xaml** | WPF visual layout (Neon dark theme, 5-tab navigation) |
