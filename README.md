<div align="center">

<img src="assets/logo.png" alt="Win-Debloat7 Logo" width="140" height="140">

# Win-Debloat7
## Reclaim Your Operating System
**The professional-grade Windows optimization toolkit.**
Debloat, harden security, and maximize performance with a single PowerShell command.
**Open Source & Transparent.**

![GitHub release](https://img.shields.io/github/v/release/tomytate/Win-Debloat7?style=for-the-badge&color=00D9FF)
![GitHub downloads](https://img.shields.io/github/downloads/tomytate/Win-Debloat7/total?style=for-the-badge&color=00D9FF)
![GitHub stars](https://img.shields.io/github/stars/tomytate/Win-Debloat7?style=for-the-badge&color=00D9FF)
![License](https://img.shields.io/github/license/tomytate/Win-Debloat7?style=for-the-badge&color=00D9FF)
![PowerShell 7.5+](https://img.shields.io/badge/PowerShell-7.5+-00D9FF?style=for-the-badge&logo=powershell)

**[🚀 Quick Install](#-installation) • [📖 Features](#-what-can-win-debloat7-do) • [🏗️ Profiles](docs/Profiles.md) • [🐛 Issues](https://github.com/tomytate/Win-Debloat7/issues) • [💬 Discussions](https://github.com/tomytate/Win-Debloat7/discussions)**

</div>

---

![Dashboard Preview](assets/ss-dashboard.png)

---

## ⚡ What is Win-Debloat7?

Win-Debloat7 is not just a script—it is a **professional-grade configuration engine** designed to strip Windows 10 and 11 down to the essentials and rebuild it for **performance**.

Unlike legacy "black box" tools that blindly delete registry keys, Win-Debloat7 treats your system configuration **as code**. It uses audit-friendly **YAML profiles**, creates **encrypted system snapshots** before every change, and provides real-time telemetry monitoring so you can see what's happening.

> **"It's like `terraform apply` for your personal Gaming PC."**

### Why Win-Debloat7 vs Others?

| Feature | Win-Debloat7 | Typical Scripts |
|---------|--------------|------------------------|
| **Config as Code** | ✅ YAML profiles + version control | ❌ Script flags |
| **Encrypted Rollback** | ✅ DPAPI snapshots | ⚠️ Restore points only |
| **Service Presets** | ✅ JSON database (Privacy/Gaming/Security) | ❌ Hardcoded |
| **Hardware-Aware** | ✅ Detects RAM/GPU, suggests profiles | ❌ One-size-fits-all |
| **Audit Trail** | ✅ Structured logs + reports | ⚠️ Console output |
| **Unattended Deploy** | ✅ `-Profile config.yaml -Unattended` | ⚠️ Limited |

---

## 👥 Who This Is For

### Designed For:
- ✅ **Power Users**: Who want repeatable configs, not one-off cleanups.
- ✅ **Gamers**: Who need low-latency network tweaks + Ultimate Performance mode.
- ✅ **Sysadmins**: Who need to deploy standard baselines across multiple machines.
- ✅ **Privacy Advocates**: Who want verifiable telemetry blocking.

### Not Designed For:
- ❌ **Corporate Workstations**: May break domain policies or VPNs.
- ❌ **"Click-Next" Users**: Requires reading warnings and understanding implications.

---

## 📦 Installation

### ⚡ Instant Deploy (Copy & Paste)

Open PowerShell **as Administrator** and run:

#### Option A: Standard Edition (Recommended) 🛡️
Safe, stable, and compliant. No compiled binaries.
```powershell
iwr -useb https://raw.githubusercontent.com/tomytate/Win-Debloat7/main/setup-standard.ps1 | iex
```

#### Option B: Extras Edition (Advanced) ⚠️
Includes **Defender Remover** + **MAS**. May trigger Antivirus warnings.
```powershell
iwr -useb https://raw.githubusercontent.com/tomytate/Win-Debloat7/main/setup-extras.ps1 | iex
```

<details>
<summary><b>Alternative: Download Single-File EXE</b></summary>
<br>
1. Download from <b><a href="https://github.com/tomytate/Win-Debloat7/releases">Releases Page</a></b>:
   - <b>Win-Debloat7.exe</b> (Standard)
   - <b>Win-Debloat7-Extras.exe</b> (Extras)
2. Right-click → <b>Run as Administrator</b>.
3. Launcher auto-installs PowerShell 7.5 if missing.
</details>

<details>
<summary><b>For Chocolatey Users</b></summary>
<br>
<pre>choco install win-debloat7</pre>
</details>

<details>
<summary><b>For Developers (Source)</b></summary>
<br>
<pre>
git clone https://github.com/tomytate/Win-Debloat7.git
cd Win-Debloat7
.\Win-Debloat7.ps1
</pre>
</details>

---

## 🏗️ For Sysadmins: Deploy at Scale

For sysadmins deploying to multiple machines, **define your infrastructure in a simple YAML file:**

```yaml
metadata:
  name: "My Workstation"
  version: 1.0
bloatware:
  removal_mode: "Custom"
  custom_list:
    - "Microsoft.BingNews"
    - "Microsoft.XboxApp"
    - "TikTok"
privacy:
  telemetry_level: "Security"
  disable_copilot: true
performance:
  powerplan: "Ultimate"
```

Run it headlessly:
```powershell
./Win-Debloat7.exe -Profile my-config.yaml -Unattended
```

**Result:** Auditable, version-controlled system configs.

---

## 🛠️ What Can Win-Debloat7 Do?

### 🧹 Deep-Dive: What Can It Debloat?

#### 1. Consumer Bloatware (The Junk)
**Pre-installed sponsored applications that eat RAM and bandwidth.**

| Category | Targeted Apps (Examples) |
|----------|--------------------------|
| **Social Media** | Facebook, Instagram, Twitter/X, TikTok, LinkedIn |
| **Streaming** | Spotify, Netflix, Disney+, Prime Video, Pandora |
| **Games** | Candy Crush, Bubble Witch, FarmVille, March of Empires |
| **Microsoft** | Get Started, Tips, Feedback Hub, Mixed Reality Portal |

#### 2. AI & Telemetry (The Spyware)
**Features that track your activity or consume NPU/GPU resources unnecessarily.**

- **Microsoft Copilot**: Completely disabled (Taskbar, Sidebar, Win+C).
- **Windows Recall**: AI screenshotting features disabled at the policy level.
- **AI Services**: `AIFabric` and `WindowsAI` services neutralized (25H2).
- **Telemetry**: `DiagTrack` service disabled, hosts file blocked.
- **Advertising ID**: Reset and disabled to stop ad tracking.

#### 3. Core System Components (Advanced)
**Available in "Extras" Edition only:**

- **Microsoft Edge**: Force uninstall (WebView2 preserved for compatibility).
- **OneDrive**: Complete nuclear removal.
- **Windows Defender**: Integrated Defender Remover support.

---

## 🛡️ Safety-First Architecture

We know that debloating can be **risky**. Win-Debloat7 is built with enterprise-grade safety rails:

- **Encrypted Snapshots**: Before *any* change is applied, we create a full system state backup.
  - **Technology**: Uses `ConvertTo-CliXml` with DPAPI encryption.
  - **Frequency**: Bypasses the Windows "1 restore point per 24h" limit.
- **One-Click Rollback**: Broke something? Restore your exact service config and registry state in seconds from the GUI.
- **Non-Destructive Defaults**: The Standard edition will never touch critical components (like the Store or Update service) unless you explicitly ask it to.

---

## 🔒 Trust & Verification

### Before You Run Any Debloat Tool (Including Ours):

1. ✅ **Verify the source**: Only download from [github.com/tomytate/Win-Debloat7/releases](https://github.com/tomytate/Win-Debloat7/releases).
2. ✅ **Check SHA256 hashes**: Every release includes `SHA256SUMS.txt`.
3. ✅ **Understand Standard vs Extras**:
   - **Standard Edition** (`Win-Debloat7.exe`): Clean, no AV warnings.
   - **Extras Edition** (`Win-Debloat7-Extras.exe`): Contains Defender Remover + MAS → **Expected** AV flags.

### Transparency Promise

- 🔓 **100% Open Source**: No compiled binaries in Standard edition.
- 📋 **Structured Logs**: Every action logged to `C:\ProgramData\Win-Debloat7\Logs`.
- 🔐 **Encrypted Snapshots**: Rollback state stored with Windows DPAPI.

**If Standard Edition triggers AV warnings, [report it immediately](https://github.com/tomytate/Win-Debloat7/issues) as a false positive.**

---

<div align="center">

### 🎯 Ready to Reclaim Your PC?

```powershell
iwr -useb https://raw.githubusercontent.com/tomytate/Win-Debloat7/main/setup-standard.ps1 | iex
```

**[📥 Download Latest Release](https://github.com/tomytate/Win-Debloat7/releases) • [📖 Read the Docs](docs/Home.md) • [💬 Join Discussions](https://github.com/tomytate/Win-Debloat7/discussions)**

<br>

Made with ⚡ by **Tomy Tate** | Licensed under **MIT**

*Enjoy a faster, cleaner Windows experience.*

</div>
