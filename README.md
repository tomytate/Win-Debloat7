# Win-Debloat7 🚀

<div align="center">

### **The Power User's Windows Optimization Framework**

*Take back control of your Windows experience*

![PowerShell 7.5](https://img.shields.io/badge/PowerShell-7.5+-5391FE?style=for-the-badge&logo=powershell&logoColor=white)
![Windows 11](https://img.shields.io/badge/Windows_11-25H2_Ready-0078D4?style=for-the-badge&logo=windows11&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-brightgreen?style=for-the-badge)
![Stars](https://img.shields.io/github/stars/tomytate/Win-Debloat7?style=for-the-badge)

---

**Author:** [Tomy Tolledo](https://github.com/tomytate) • **Formerly:** Win-Debloat-Tools

[🚀 Quick Start](#-quick-start) • [✨ Features](#-features) • [📦 Installation](#-installation) • [🎮 Profiles](#-profiles) • [📖 Documentation](#-documentation)

</div>

---

## 🎯 Why Win-Debloat7?

> **Win-Debloat7** is a complete rewrite designed from the ground up for **Windows 11 25H2** and **PowerShell 7.5**. 
> Unlike traditional scripts, it's a modular framework with YAML-based profiles, encrypted snapshots, and a beautiful Steel Blue TUI.

### Before vs After

| Feature | Traditional Scripts | Win-Debloat7 |
|---------|---------------------|--------------|
| Configuration | Hardcoded | ✅ YAML Profiles |
| Undo/Restore | None | ✅ Encrypted Snapshots |
| Interface | Basic text | ✅ Steel Blue TUI |
| Windows 11 25H2 | Partial | ✅ Copilot, Recall, Widgets |
| Modern PowerShell | 5.1 | ✅ 7.5+ with classes |
| Error Handling | Basic | ✅ Structured logging |

---

## ✨ Features

<table>
<tr>
<td width="50%">

### 🗑️ Bloatware Removal
- Remove 40+ pre-installed apps
- Target Microsoft & 3rd party bloat
- **25H2 Ready:** Copilot, Dev Home, Widgets
- Custom exclude lists

</td>
<td width="50%">

### 🔒 Privacy Hardening
- Telemetry (Security/Basic/Full)
- Disable Advertising ID
- Activity History controls
- **Windows Recall** disable
- **Copilot** disable

</td>
</tr>
<tr>
<td width="50%">

### ⚡ Performance Tuning
- Power Plans (Balanced/High/Ultimate)
- Visual Effects optimization
- Game Bar/DVR controls
- Background Apps management
- Network throttling removal

</td>
<td width="50%">

### 💾 State Management
- System snapshots before changes
- Registry state backup
- Service state backup
- **DPAPI encrypted** snapshots
- One-click restore

</td>
</tr>
</table>

---

## 🚀 Quick Start

```powershell
# 1. Open PowerShell 7.5+ as Administrator
# 2. Clone and run
git clone https://github.com/tomytate/Win-Debloat7.git
cd Win-Debloat7
./Win-Debloat7.ps1
```

That's it! The interactive menu will guide you through the rest.

---

## 📦 Installation

### Prerequisites
- **Windows 10/11** (Windows 11 25H2 recommended)
- **PowerShell 7.5+** ([Download](https://github.com/PowerShell/PowerShell/releases) or `winget install Microsoft.PowerShell`)
- **Administrator privileges**

### Option 1: Clone (Recommended)
```powershell
git clone https://github.com/tomytate/Win-Debloat7.git
cd Win-Debloat7
./Win-Debloat7.ps1
```

### Option 2: Download ZIP
1. Download the [latest release](https://github.com/tomytate/Win-Debloat7/releases)
2. Extract to a folder
3. Right-click `Win-Debloat7.ps1` → Run with PowerShell 7

---

## 🎮 Usage Modes

### Interactive Mode (TUI)
```powershell
./Win-Debloat7.ps1
```

Beautiful menu-driven interface:
```
╔══════════════════════════════════════════╗
║         Win-Debloat7 - Power User        ║
╚══════════════════════════════════════════╝
   v1.1 | PowerShell 7.5 | 25H2 Ready

Choose an option:
  [1] Quick Debloat (Recommended)
  [2] Select Profile...
  [3] System Info
  [4] Snapshots / Restore
  [Q] Quit
```

### CLI / Unattended Mode
```powershell
# Apply a specific profile directly
./Win-Debloat7.ps1 -ProfileFile profiles/gaming.yaml

# For automation/deployment
./Win-Debloat7.ps1 -ProfileFile profiles/moderate.yaml -Unattended
```

---

## 🎮 Profiles

Pre-built profiles in the `profiles/` directory:

| Profile | Use Case | Bloatware | Telemetry | Power Plan |
|---------|----------|-----------|-----------|------------|
| **moderate.yaml** | Daily driver (recommended) | Moderate | Basic | Balanced |
| **gaming.yaml** | Maximum performance | Aggressive | Security | Ultimate |

### Custom Profiles

Create your own in `profiles/myprofile.yaml`:

```yaml
metadata:
  name: "MyProfile"
  version: "1.0.0"
  description: "My custom optimization profile"

bloatware:
  removal_mode: "Moderate"          # Conservative | Moderate | Aggressive
  exclude_list:
    - "Microsoft.WindowsStore"
    - "Microsoft.XboxApp"           # Keep Xbox if you game

privacy:
  telemetry_level: "Basic"          # Security | Basic | Full
  disable_copilot: true
  disable_recall: true
  disable_advertising_id: true
  disable_activity_history: true
  disable_location_tracking: false

performance:
  power_plan: "HighPerformance"     # Balanced | HighPerformance | Ultimate
  visual_effects: "Appearance"      # Appearance | Performance
  disable_game_bar: false
  disable_background_apps: true
```

See [`profiles/schema.yaml`](profiles/schema.yaml) for all available options.

---

## 📂 Project Structure

```
Win-Debloat7/
├── 📄 Win-Debloat7.ps1     # Entry point
├── 📄 Win-Debloat7.psd1    # Module manifest
├── 📁 src/
│   ├── 📁 core/            # Framework modules
│   │   ├── Logger.psm1     #   Structured logging with rotation
│   │   ├── Config.psm1     #   YAML parsing & validation
│   │   ├── State.psm1      #   Snapshot/restore management
│   │   └── Registry.psm1   #   Safe registry operations
│   ├── 📁 modules/         # Feature modules
│   │   ├── Bloatware/      #   UWP app removal (40+ apps)
│   │   ├── Privacy/        #   Telemetry, Copilot, Recall
│   │   ├── Performance/    #   Power plans, visual effects
│   │   └── Windows11/      #   Version detection, 25H2 support
│   └── 📁 ui/              # Terminal UI
│       ├── Colors.psm1     #   Steel Blue theme
│       └── Menu.psm1       #   Interactive menus
├── 📁 profiles/            # YAML configurations
│   ├── moderate.yaml       #   Recommended default
│   ├── gaming.yaml         #   Maximum performance
│   └── schema.yaml         #   Configuration schema
└── 📁 build/               # Build scripts
    ├── Build.ps1           #   Release packaging
    └── Sign-Scripts.ps1    #   Code signing
```

---

## 🔒 Snapshot & Restore

Win-Debloat7 automatically captures system state so you can always roll back.

### Creating a Snapshot
```powershell
# Via menu: [4] Snapshots → [C] Create
# Or programmatically:
New-WinDebloat7Snapshot -Name "Pre-Optimization"
```

### Restoring from Snapshot
```powershell
# Via menu: [4] Snapshots → [R] Restore
# Or programmatically:
Restore-WinDebloat7Snapshot -SnapshotId "<GUID>"
```

### Encrypted Snapshots
```powershell
# For sensitive environments - uses Windows DPAPI
New-WinDebloat7Snapshot -Name "Secure" -Encrypt
```

---

## 📖 Documentation

### PowerShell 7.5 Features Used

This project leverages modern PowerShell 7.5 capabilities:

- `ConvertTo-CliXml` / `ConvertFrom-CliXml` for snapshot serialization
- `using namespace` declarations
- Null-coalescing operators (`??`)
- Ternary operators (`? :`)
- PowerShell classes for type safety
- `Install-PSResource` (PSResourceGet)
- Structured error handling

### Available Functions

```powershell
# Core
Start-WD7Logging              # Initialize logging
Write-Log                     # Structured logging
Import-WinDebloat7Config      # Load YAML profile

# Snapshots
New-WinDebloat7Snapshot       # Create snapshot
Restore-WinDebloat7Snapshot   # Restore snapshot
Get-WinDebloat7Snapshot       # List snapshots

# Modules
Remove-WinDebloat7Bloatware   # Remove bloatware
Set-WinDebloat7Privacy        # Apply privacy settings
Set-WinDebloat7Performance    # Apply performance settings
Get-WindowsVersionInfo        # Windows version detection
```

---

## 🛡️ Security

- **No `Invoke-Expression`** - Zero code injection risk
- **No hardcoded credentials** - Clean codebase
- **YAML schema validation** - All input validated
- **DPAPI encryption** - Optional snapshot protection
- **ACL validation** - Registry permissions checked
- **No BinaryFormatter** - Modern serialization only

See [SECURITY.md](SECURITY.md) for vulnerability reporting.

---

## 🤝 Contributing

Contributions welcome! See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

```powershell
# Development setup
git clone https://github.com/tomytate/Win-Debloat7.git
cd Win-Debloat7

# Run tests (PowerShell 7.5 required)
Invoke-ScriptAnalyzer -Path . -Recurse -Settings PSGallery
```

---

## ⚠️ Disclaimer

> **Use at your own risk.**
> 
> This tool modifies system configurations including registry keys and removes Windows applications. 
> While snapshots are provided for recovery, always create a **System Restore Point** before use.
> 
> The author is not responsible for any system issues resulting from the use of this tool.

---

## 📜 License

MIT License - see [LICENSE](LICENSE) for details.

---

<div align="center">

**Made with ❤️ by [Tomy Tolledo](https://github.com/tomytate)**

⭐ Star this project if you find it useful!

</div>
