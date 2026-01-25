# Installation Guide

Win-Debloat7 is designed to run on **Windows 10 (22H2+)** or **Windows 11**.

## Prerequisites

1.  **PowerShell 7.5+**: The script uses features newly introduced in PowerShell 7.5 (CLI XML encryption, array optimization).
    *   [Download Here](https://github.com/PowerShell/PowerShell/releases)
    *   Or install via Winget: `winget install Microsoft.PowerShell`

2.  **Administrator Rights**: The script requires elevated privileges to modify registry and services.

---

## 📦 Method 1: Winget (Recommended)

The easiest way to install and keep updated.

```powershell
winget install TomyTate.WinDebloat7
```

Once installed, simply run `Win-Debloat7` from any terminal.

---

## 🍫 Method 2: Chocolatey

For users who prefer Chocolatey package manager.

```powershell
choco install win-debloat7
```

---

## 📂 Method 3: Portable / Manual

For portable usage (USB drives) or offline systems.

1.  Go to the **[Releases Page](https://github.com/tomytate/Win-Debloat7/releases)**.
2.  Download the **Standard Edition** ZIP (`Win-Debloat7-vX.X.X-Standard.zip`).
3.  Extract the archive.
4.  Right-click `Win-Debloat7.ps1` and select "Run with PowerShell 7".
    *   *Or run from terminal:* `.\Win-Debloat7.ps1`

### ⚠️ Extras Edition
For advanced users needing **Defender Remover** or **MAS** (Activation), download the **Extras Edition**.  
*Note: This will likely trigger your Antivirus. You must create an exclusion for the extraction folder.*
