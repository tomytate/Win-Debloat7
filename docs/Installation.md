# Installation Guide

Win-Debloat7 is designed to run on **Windows 10 (22H2+)** or **Windows 11**.

## Prerequisites

1.  **PowerShell 7.5+**: The script uses features exclusive to PowerShell 7.5.
    *   **Auto-Installed**: If you use `Win-Debloat7.exe`, it will automatically install this for you.
    *   **Manual**: Only required if running the `.ps1` script directly. [Download Here](https://github.com/PowerShell/PowerShell/releases)

2.  **Administrator Rights**: The script requires elevated privileges to modify registry and services.

---

## ⚡ Method 1: Instant Deploy (Recommended)

Open PowerShell **as Administrator** and paste one command:

### Standard Edition 🛡️
Safe, stable, and compliant. No compiled binaries.
```powershell
iwr -useb https://raw.githubusercontent.com/tomytate/Win-Debloat7/main/setup-standard.ps1 | iex
```

### Extras Edition ⚠️
Includes **Defender Remover** + **MAS**. Will trigger Antivirus warnings.
```powershell
iwr -useb https://raw.githubusercontent.com/tomytate/Win-Debloat7/main/setup-extras.ps1 | iex
```

---

## 🍫 Method 2: Chocolatey

For users who prefer Chocolatey package manager.

```powershell
choco install win-debloat7
```

---

## 📂 Method 3: Direct Download (Portable)

For portable usage (USB drives) or offline systems.

1.  Go to the **[Releases Page](https://github.com/tomytate/Win-Debloat7/releases)**.
2.  Download the **Single-File Executable**:
    *   **Standard**: `Win-Debloat7.exe` (Recommended)
    *   **Extras**: `Win-Debloat7-Extras.exe`
3.  **Right-click → Run as Administrator.** No extraction needed.
4.  The launcher will auto-install PowerShell 7.5 if missing.

---

## 🛠️ Method 4: From Source (Developers)

```powershell
git clone https://github.com/tomytate/Win-Debloat7.git
cd Win-Debloat7
./Win-Debloat7.ps1
```

### Verify Integrity
```powershell
# Run compliance tests
Invoke-Pester -Path tests/Overall.Tests.ps1 -Output Detailed
```

---

## ⚠️ Extras Edition Notice
The Extras edition contains **Defender Remover** and **MAS** (Activation Scripts), which are flagged by antivirus software as "HackTool" or "PUP". This is **expected behavior**. Use the Standard Edition if you do not need these tools.
