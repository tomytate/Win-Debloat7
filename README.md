<div align="center">

<img src="assets/logo.png" alt="Win-Debloat7 Logo" width="140" height="140">

# Reclaim Your Operating System
**The professional-grade Windows optimization toolkit.**
Debloat, harden security, and maximize performance with a single PowerShell command.
**Open Source & Transparent.**

[![GitHub Release](https://img.shields.io/github/v/release/tomytate/Win-Debloat7?style=for-the-badge&color=00D4FF)](https://github.com/tomytate/Win-Debloat7/releases)
[![License](https://img.shields.io/github/license/tomytate/Win-Debloat7?style=for-the-badge)](LICENSE)
[![PowerShell](https://img.shields.io/badge/PowerShell-7.4+-blue?style=for-the-badge&logo=powershell)](https://github.com/PowerShell/PowerShell)

</div>

---

![Dashboard Preview](assets/ss-dashboard.png)

</div>

---

## ⚡ What is Win-Debloat7?

**Win-Debloat7** is not just a script—it is a **professional grade configuration engine** designed to strip Windows 10 and 11 down to the essentials and rebuild it for performance.

Unlike legacy "black box" tools that blindly delete registry keys, Win-Debloat7 treats your system configuration as **code**. It uses audit-friendly YAML profiles, creates encrypted system snapshots before every change, and provides real-time telemetry monitoring so you can **see** what's happening.

> **"It's like `terraform apply` for your personal Gaming PC."**

---

## 🔥 Deep-Dive: What Can It Debloat?

Win-Debloat7 uses aggressive heuristic scanning to identify and neutralize unwanted software at the system level.

### 1. Consumer Bloatware (The "Junk")
Pre-installed sponsored applications that eat RAM and bandwidth.
| Category | Targeted Apps (Examples) |
| :--- | :--- |
| **Social Media** | Facebook, Instagram, Twitter/X, TikTok, LinkedIn |
| **Streaming** | Spotify, Netflix, Disney+, Prime Video, Pandora |
| **Games** | Candy Crush, Bubble Witch, FarmVille, March of Empires, Solitaire Collection |
| **Microsoft Promotions** | Get Started, Tips, Feedback Hub, Mixed Reality Portal, 3D Viewer |

### 2. AI & Telemetry (The "Spyware")
Features that track your activity or consume NPU/GPU resources unnecessarily.
-   🚫 **Microsoft Copilot**: Completely disabled (Taskbar, Sidebar, Win+C).
-   🚫 **Windows Recall**: AI screenshotting features disabled at the policy level.
-   🚫 **AI Services**: `AIFabric` and `WindowsAI` services neutralized (25H2).
-   🚫 **Telemetry**: `DiagTrack` service disabled, hosts file blocked.
-   🚫 **Advertising ID**: Reset and disabled to stop ad tracking.

### 3. Core System Components (Advanced)
*Available in "Extras" Edition only*
-   💀 **Microsoft Edge**: Force uninstall (WebView2 preserved for compatibility).
-   💀 **OneDrive**: Complete nuclear removal.
-   💀 **Windows Defender**: Integrated "Defender Remover" support.

---

## 🛡️ Safety-First Architecture

We know that "debloating" can be risky. Win-Debloat7 is built with **enterprise-grade safety rails**:

-   **📸 Encrypted Snapshots**: Before *any* change is applied, we create a full system state backup.
    -   *Technology*: Uses `ConvertTo-CliXml` with DPAPI encryption.
    -   *Frequency*: Bypasses the Windows "1 restore point per 24h" limit.
-   **↩️ One-Click Rollback**: Broke something? Restore your exact service config and registry state in seconds from the GUI.
-   **💾 Non-Destructive Defaults**: The "Standard" edition will never touch critical components (like the Store or Update service) unless you explicitly ask it to.

---

## 🚀 Key Features

<table>
<tr>
<td width="50%" valign="top">

### 🎮 Gaming Mode
Optimizes Windows specifically for low-latency performance.
-   **Power Plan**: Unlocks "Ultimate Performance" mode.
-   **Thread Priority**: Sets GPU/Games to "High" priority in MMCSS.
-   **Network**: Disables Nagle's Algorithm (TcpNoDelay).
-   **Input**: Removes mouse acceleration curves.

### 👁️ Privacy Command Center
A visual dashboard that doesn't just "toggle" settings, but **monitors** them.
-   Live connection counter.
-   Real-time Telemetry Status indicator.
-   Privacy Score (0-100) based on active audits.

</td>
<td width="50%" valign="top">

### 📦 Software & Driver Manager
Reinstall and **Update** your essential software stack.
-   **Winget Integration**: Install *and Update* apps (`winget upgrade --all`) with **automatic Chocolatey fallback** if Winget fails.
-   **Driver Updates**: Update GPU (NVIDIA/AMD) and System drivers via Windows Update or SDIO.
-   **One-Click Essentials**: Install Browser, Discord, Steam, 7Zip in seconds.
-   Clean, bloat-free installers only.

### 🔧 System Repair Hub
Don't just break things—fix them.
-   **Network Reset**: Flushes DNS, resets Winsock/TCP stack.
-   **Update Fixer**: Resets Windows Update components when stuck.
-   **SFC/DISM**: One-click system integrity scans.

</td>
</tr>
</table>

---

## 📦 Installation

Win-Debloat7 is a portable application. No installation required.

### Method 1: The Quick Start (One-Liner)
The fastest way to get started. Open PowerShell as Administrator and run:

```powershell
iwr -useb https://raw.githubusercontent.com/tomytate/Win-Debloat7/main/setup.ps1 | iex
```

### Method 2: The Easy Way (Self-Installing EXE)
1.  Download the latest [**Win-Debloat7.exe**](https://github.com/tomytate/Win-Debloat7/releases).
2.  Right-click and **Run as Administrator**.
3.  **No Prerequisites? No Problem.** The launcher will automatically detect if you are missing PowerShell 7.5 and install it for you before launching.

### Method 3: PowerShell (For Devs)
```powershell
# Clone the repo
git clone https://github.com/tomytate/Win-Debloat7.git
cd Win-Debloat7

# Run the script
.\Win-Debloat7.ps1
```

> **Note**: For Method 2, you must have **[PowerShell 7.5](https://github.com/PowerShell/PowerShell/releases)** installed manually.
>
> 🍫 **Chocolatey Support**: The official Chocolatey package is available! `choco install win-debloat7`

---

## ⚖️ Editions: Standard vs Extras

We offer two flavors to suit your risk tolerance.

| Feature | **Standard Edition** ✅ | **Extras Edition** ⚠️ |
| :--- | :---: | :---: |
| **Best For** | 99% of Users | Power Users / Sysadmins |
| **Safety Level** | **Safe** | **Risky** |
| **Bloat Removal** | Consumer Apps (Social, Games) | All Apps + System Apps |
| **Privacy Tweaks** | Telemetry, Ads, Copilot | Telemetry, Ads, Copilot |
| **Windows Activation** | ❌ | ✅ (MAS Integration) |
| **Defender Removal** | ❌ | ✅ (Defender Remover) |
| **Edge Removal** | ❌ | ✅ (Force Uninstall) |
| **Antivirus Flags** | Clean | Likely (due to tools used) |

**We strongly recommend start with the Standard Edition.**

---

## ⚙️ Advanced: Custom Profiles (YAML)

For sysadmins deploying to multiple machines, define your infrastructure in a simple YAML file:

```yaml
metadata:
  name: "My Workstation"
  version: "1.0"

bloatware:
  removal_mode: "Custom"
  custom_list:
    - "Microsoft.BingNews"
    - "Microsoft.XboxApp"
    - "TikTok"

privacy:
  telemetry_level: "Security"
  disable_copilot: true
  disable_recall: true

performance:
  power_plan: "Ultimate"
```

Run it headlessly:
```powershell
.\Win-Debloat7.exe -Profile "my-config.yaml" -Unattended
```

---

## ⚠️ Disclaimer

**Liability**: While we have engineered this tool with safety in mind (Snapshots, Safe Defaults), modifying Windows system files always carries inherent risk.
1.  **Always** backup your important data.
2.  **Test** on a VM or secondary machine first.
3.  **We are not responsible** for bricked OS installs or lost data.

---

<div align="center">

**Enjoy a faster, cleaner Windows experience.**
<br>
Made with ❤️ by [Tomy Tate](https://github.com/tomytate)

</div>
