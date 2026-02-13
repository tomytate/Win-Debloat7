<div align="center">

<img src="assets/logo.png" alt="Win-Debloat7 — Windows 10 and 11 Debloater, Optimizer, and Privacy Tool" width="140" height="140">

# Win-Debloat7

### The Ultimate Windows 10 & 11 Debloater, Optimizer, and Privacy Hardener

**Remove bloatware. Disable telemetry. Maximize performance. One command.**
Open source. Transparent. Reversible. Built on PowerShell 7.5+.

[![GitHub Release](https://img.shields.io/github/v/release/tomytate/Win-Debloat7?style=for-the-badge&color=00D9FF&label=Latest)](https://github.com/tomytate/Win-Debloat7/releases)
[![Total Downloads](https://img.shields.io/github/downloads/tomytate/Win-Debloat7/total?style=for-the-badge&color=00D9FF&label=Downloads)](https://github.com/tomytate/Win-Debloat7/releases)
[![GitHub Stars](https://img.shields.io/github/stars/tomytate/Win-Debloat7?style=for-the-badge&color=00D9FF)](https://github.com/tomytate/Win-Debloat7/stargazers)
[![MIT License](https://img.shields.io/github/license/tomytate/Win-Debloat7?style=for-the-badge&color=00D9FF)](LICENSE)
[![PowerShell 7.5+](https://img.shields.io/badge/PowerShell-7.5+-00D9FF?style=for-the-badge&logo=powershell)](https://github.com/PowerShell/PowerShell/releases)
[![Pester Tests](https://img.shields.io/badge/Tests-35%2F35_Passed-00FF88?style=for-the-badge)](tests/)

**[⚡ Quick Install](#-quick-install) · [📖 Features](#-features-overview) · [🏗️ Profiles](docs/Profiles.md) · [📚 Wiki](docs/Home.md) · [🐛 Report Bug](https://github.com/tomytate/Win-Debloat7/issues)**

</div>

---

<p align="center">
  <img src="assets/ss-dashboard.png" alt="Win-Debloat7 WPF Dashboard — Dark theme GUI for Windows debloating and optimization" width="850">
</p>

---

## 📋 Table of Contents

- [What is Win-Debloat7?](#-what-is-win-debloat7)
- [Quick Install](#-quick-install)
- [Features Overview](#-features-overview)
- [Bloatware Removal](#-bloatware-removal)
- [Privacy & AI Disablement](#-privacy--ai-disablement)
- [Performance Optimization](#-performance-optimization)
- [Network & DNS Configuration](#-network--dns-configuration)
- [Windows 11 UI Customization](#-windows-11-ui-customization)
- [Enterprise Deployment (Sysprep)](#-enterprise-deployment--sysprep)
- [Safety & Rollback](#-safety--encrypted-rollback)
- [Why Win-Debloat7?](#-why-win-debloat7-vs-alternatives)
- [Trust & Verification](#-trust--verification)
- [FAQ](#-frequently-asked-questions)
- [Contributing](#-contributing)

---

## ⚡ What is Win-Debloat7?

**Win-Debloat7** is a professional-grade, open-source Windows debloating and optimization framework. It removes pre-installed bloatware, disables invasive telemetry and AI features, optimizes system performance, and hardens privacy — all with **one-click rollback** via encrypted snapshots.

Unlike legacy debloat scripts that blindly delete registry keys, Win-Debloat7 treats your system configuration **as code**. It uses audit-friendly YAML profiles, creates DPAPI-encrypted snapshots before every change, and exports structured logs for full transparency.

> **"It's like `terraform apply` for your Windows PC."**

### Key Stats (v1.3.0)

| Metric | Value |
|--------|-------|
| **Modules** | 28 registered |
| **Functions** | 92 exported |
| **Bloatware Patterns** | 80+ apps detected |
| **DNS Providers** | 12+ (including family/malware variants) |
| **Service Presets** | 4 intelligent profiles |
| **Test Coverage** | 35/35 Pester tests passed |
| **PSScriptAnalyzer** | 0 errors |

---

## 🚀 Quick Install

Open **PowerShell as Administrator** and paste one command:

### Option A: Standard Edition (Recommended) 🛡️
Clean, open-source, no AV warnings. Safe for all environments.
```powershell
iwr -useb https://raw.githubusercontent.com/tomytate/Win-Debloat7/main/setup-standard.ps1 | iex
```

### Option B: Extras Edition (Advanced) ⚠️
Includes **Defender Remover** + **MAS**. Will trigger Antivirus warnings.
```powershell
iwr -useb https://raw.githubusercontent.com/tomytate/Win-Debloat7/main/setup-extras.ps1 | iex
```

<details>
<summary><b>📥 Alternative: Download Single-File EXE</b></summary>
<br>

1. Download from the **[Releases Page](https://github.com/tomytate/Win-Debloat7/releases)**:
   - **Win-Debloat7.exe** (Standard)
   - **Win-Debloat7-Extras.exe** (Extras)
2. Right-click → **Run as Administrator**.
3. The launcher auto-installs PowerShell 7.5 if missing.
</details>

<details>
<summary><b>🍫 Alternative: Chocolatey</b></summary>
<br>
<pre>choco install win-debloat7</pre>
</details>

<details>
<summary><b>🛠️ Alternative: Clone from Source</b></summary>
<br>
<pre>
git clone https://github.com/tomytate/Win-Debloat7.git
cd Win-Debloat7
.\Win-Debloat7.ps1
</pre>
</details>

**Requirements:** Windows 10 (22H2+) or Windows 11 · PowerShell 7.5+ · Administrator privileges

---

## 📖 Features Overview

Win-Debloat7 ships with **92 functions** across **28 modules**, organized into 9 feature areas:

| Feature | Description | Key Functions |
|---------|-------------|---------------|
| 🧹 **Bloatware Removal** | Remove 80+ pre-installed apps with O(N) regex | `Remove-WinDebloat7Bloatware` |
| 🔒 **Privacy Hardening** | Disable telemetry, block tracking domains | `Set-WinDebloat7Privacy` |
| 🤖 **AI Disablement** | Neutralize Copilot, Recall, Click-to-Do | `Disable-WinDebloat7AIRecall` |
| ⚡ **Performance Tuning** | Ultimate power plan, service presets | `Set-WinDebloat7Performance` |
| 🌐 **Network & DNS** | 12+ DNS providers, IPv6 toggle | `Set-WinDebloat7DNS` |
| 🎮 **Gaming Mode** | Nagle's algorithm, Game DVR, GPU priority | `Set-WinDebloat7Gaming` |
| 🖥️ **UI Customization** | Taskbar, context menu, Start Menu tweaks | `Set-WinDebloat7TaskbarAlignment` |
| 🔧 **System Repair** | 4-step industrial repair sequence | `Repair-WinDebloat7System` |
| 🏢 **Enterprise (Sysprep)** | OEM image deployment, headless mode | `Invoke-WinDebloat7SysprepDefaults` |

---

## 🧹 Bloatware Removal

Removes pre-installed Appx packages using **O(N) regex matching** (50x faster than legacy nested-loop approaches).

### What Gets Removed

| Category | Examples |
|----------|----------|
| **Social Media** | Facebook, Instagram, Twitter/X, TikTok, LinkedIn |
| **Streaming** | Spotify, Netflix, Disney+, Prime Video, Pandora |
| **Casual Games** | Candy Crush, Bubble Witch, FarmVille, March of Empires |
| **Microsoft Bloat** | Get Started, Tips, Feedback Hub, Mixed Reality Portal, News |
| **OEM Bloatware** | HP Support Assistant, Dell SupportAssist, Lenovo Vantage, Acer Care Center |

### Removal Modes
- **Conservative**: Only sponsored/promo apps
- **Moderate**: Non-essential Microsoft apps (recommended)
- **Aggressive**: Everything except Store and Calculator
- **Custom**: Define your own list via YAML profile

### Advanced Removal
- **OneDrive**: Complete nuclear removal (all traces)
- **Microsoft Edge**: Force uninstall (WebView2 preserved)
- **Xbox**: Apps + services + Game Bar

---

## 🔒 Privacy & AI Disablement

### Telemetry Blocking
- **DiagTrack** service disabled (Connected User Experiences)
- **WaaSMedicSvc** neutralized
- **100+ telemetry domains** blocked via hosts file
- **Advertising ID** reset and disabled
- **Telemetry scheduled tasks** disabled

### Windows AI Disablement Suite
Completely neutralizes Microsoft's AI integration features added in Windows 11 22H2–25H2:

| Feature | Method | Function |
|---------|--------|----------|
| **Windows Recall** | Policy + Service | `Disable-WinDebloat7AIRecall` |
| **Copilot** | Taskbar + Policy + Win+C | `Disable-WinDebloat7Copilot` |
| **Click-to-Do** | Registry override | `Disable-WinDebloat7ClickToDo` |
| **Notepad AI** | Feature flag | `Disable-WinDebloat7NotepadAI` |
| **Paint AI** | Feature flag | `Disable-WinDebloat7PaintAI` |
| **Edge AI** | Policy override | `Disable-WinDebloat7EdgeAI` |

---

## ⚡ Performance Optimization

### Power Management
- **Ultimate Performance**: Unlock and activate the hidden power plan
- **Plan Duplication**: Clone the plan for custom modifications

### Service Optimization
4 intelligent presets driven by `config/services.json`:

| Preset | Purpose | Services Affected |
|--------|---------|-------------------|
| **Privacy** | Disable telemetry services | DiagTrack, dmwappushservice, WaaSMedicSvc |
| **Performance** | Disable background services | SysMain, WSearch, Fax, PrintWorkflow |
| **Security** | Harden attack surface | RemoteRegistry, SMB1, NetBIOS |
| **Minimal** | Bare essentials only | Combined Privacy + Performance |

### Gaming Tweaks
- Disable **Nagle's Algorithm** (SystemResponsiveness = 0)
- Disable **Game DVR / Game Bar** background recording
- GPU task **priority elevation**
- **Network latency** optimization

---

## 🌐 Network & DNS Configuration

Set your DNS provider in one command. Database in `config/dns.json`.

| Provider | Primary | Secondary | Type |
|----------|---------|-----------|------|
| Cloudflare | 1.1.1.1 | 1.0.0.1 | Standard |
| Cloudflare Malware | 1.1.1.2 | 1.0.0.2 | Security |
| Cloudflare Family | 1.1.1.3 | 1.0.0.3 | Family Safe |
| Google | 8.8.8.8 | 8.8.4.4 | Standard |
| Quad9 | 9.9.9.9 | 149.112.112.112 | Security |
| AdGuard | 94.140.14.14 | 94.140.15.15 | Ad Blocking |
| AdGuard Family | 94.140.14.15 | 94.140.15.16 | Family Safe |
| NextDNS | Custom | Custom | Configurable |

```powershell
# Set Cloudflare DNS
Set-WinDebloat7DNS -Provider Cloudflare

# Set custom DNS
Set-WinDebloat7DNS -Provider Custom -CustomPrimary "1.2.3.4" -CustomSecondary "5.6.7.8"
```

---

## 🖥️ Windows 11 UI Customization

| Tweak | Function | Options |
|-------|----------|---------|
| **Taskbar Alignment** | `Set-WinDebloat7TaskbarAlignment` | Left, Center |
| **Context Menu** | `Set-WinDebloat7ContextMenu` | Classic (Win10), Modern (Win11) |
| **Explorer** | `Set-WinDebloat7Explorer` | Hide Gallery, Hide Home |
| **Start Menu** | `Set-WinDebloat7StartMenu` | Disable Recommended section |
| **Desktop Ads** | `Disable-WinDebloat7DesktopSpotlight` | Remove Spotlight ads |
| **Settings Ads** | `Disable-WinDebloat7Settings365Ads` | Remove M365 promotions |

---

## 🏢 Enterprise Deployment & Sysprep

Deploy Win-Debloat7 at scale with **Infrastructure as Code**:

```yaml
# my-baseline.yaml
metadata:
  name: "Corporate Workstation"
  version: 1.0
bloatware:
  removal_mode: "Moderate"
  exclude_list:
    - "Microsoft.WindowsStore"
    - "Microsoft.WindowsCalculator"
privacy:
  telemetry_level: "Security"
  disable_copilot: true
  disable_recall: true
performance:
  power_plan: "Ultimate"
```

```powershell
# Headless deployment (for RMM tools like Intune, SCCM, PDQ)
./Win-Debloat7.exe -Profile my-baseline.yaml -Unattended
```

### Sysprep / OEM Support
Apply tweaks to the **Default User** registry hive so settings persist for all future user profiles:

```powershell
Invoke-WinDebloat7SysprepDefaults
```

---

## 🛡️ Safety & Encrypted Rollback

We know debloating can be risky. Win-Debloat7 is built with **enterprise-grade safety rails**:

| Feature | Description |
|---------|-------------|
| **Encrypted Snapshots** | DPAPI-encrypted system state backup before every change |
| **One-Click Rollback** | Restore exact registry + service state from the GUI |
| **Bypass 24h Limit** | Creates snapshots without the Windows "1 per day" restriction |
| **Non-Destructive** | Standard edition never touches Store/Update unless explicitly asked |
| **Structured Logs** | Every action logged to `C:\ProgramData\Win-Debloat7\Logs` |
| **Pester Verified** | 35/35 compliance tests passed on every release |

---

## 🏆 Why Win-Debloat7 vs Alternatives?

| Feature | Win-Debloat7 | Chris Titus WinUtil | O&O ShutUp10 | Sophia Script |
|---------|:------------:|:-------------------:|:------------:|:-------------:|
| **Open Source** | ✅ MIT | ✅ MIT | ❌ Proprietary | ✅ MIT |
| **Config as Code (YAML)** | ✅ | ❌ | ❌ | ❌ |
| **Encrypted Rollback** | ✅ DPAPI | ❌ | ⚠️ Manual | ⚠️ Manual |
| **AI Disablement Suite** | ✅ 6 features | ⚠️ Partial | ⚠️ Partial | ⚠️ Partial |
| **Service Presets (JSON)** | ✅ 4 presets | ❌ | ❌ | ❌ |
| **Hardware Detection** | ✅ RAM/CPU/GPU | ❌ | ❌ | ❌ |
| **GUI + TUI** | ✅ Both | ✅ GUI | ✅ GUI | ❌ CLI only |
| **Sysprep / OEM** | ✅ | ❌ | ❌ | ❌ |
| **Unattended Deploy** | ✅ | ⚠️ Limited | ❌ | ⚠️ Limited |
| **DNS Management** | ✅ 12+ providers | ❌ | ❌ | ❌ |

---

## 🔒 Trust & Verification

### Before You Run Any Debloat Tool (Including Ours):

1. ✅ **Verify the source**: Only download from [github.com/tomytate/Win-Debloat7/releases](https://github.com/tomytate/Win-Debloat7/releases).
2. ✅ **Check SHA256 hashes**: Every release includes checksums in the Release Notes.
3. ✅ **Understand Standard vs Extras**:
   - **Standard** (`Win-Debloat7.exe`): Clean code, no AV warnings.
   - **Extras** (`Win-Debloat7-Extras.exe`): Contains Defender Remover + MAS → **Expected** AV flags.

### Transparency Promise

- 🔓 **100% Open Source**: No compiled binaries in Standard edition.
- 📋 **Structured Logs**: Every action logged with timestamps and severity levels.
- 🔐 **Encrypted Snapshots**: Rollback state stored with Windows DPAPI.
- 🧪 **Verified**: 35/35 Pester tests + 0 PSScriptAnalyzer errors on every release.

> **If Standard Edition triggers AV warnings, [report it immediately](https://github.com/tomytate/Win-Debloat7/issues) as a false positive.**

---

## ❓ Frequently Asked Questions

<details>
<summary><b>Is Win-Debloat7 safe to use?</b></summary>
<br>
Yes. The Standard edition uses only official PowerShell APIs and Group Policy modifications. Every change creates an encrypted snapshot for instant rollback. The codebase passes 35/35 Pester compliance tests.
</details>

<details>
<summary><b>Will this break Windows Update or Microsoft Store?</b></summary>
<br>
No, not with default settings. The Standard edition never touches Windows Update or Microsoft Store unless you explicitly configure it in your YAML profile. If you use Aggressive bloatware removal, Store components may be affected — use the snapshot rollback to restore.
</details>

<details>
<summary><b>Why does the Extras edition trigger my antivirus?</b></summary>
<br>
The Extras edition includes <b>Defender Remover</b> and <b>MAS</b> (Microsoft Activation Scripts). These tools modify Windows security components and are intentionally flagged as "HackTools" by antivirus software. This is expected. Use the Standard edition if you want zero AV warnings.
</details>

<details>
<summary><b>Does Win-Debloat7 work on Windows 10?</b></summary>
<br>
Yes. Win-Debloat7 supports Windows 10 (22H2+) and Windows 11 (all versions through 25H2). Some features (like AI disablement and Taskbar alignment) are Windows 11–specific.
</details>

<details>
<summary><b>Can I use this in an enterprise / Intune / SCCM deployment?</b></summary>
<br>
Yes. Use <code>-Profile config.yaml -Unattended</code> for headless deployment via any RMM tool. The Sysprep module (<code>Invoke-WinDebloat7SysprepDefaults</code>) applies settings to the Default User hive for OEM image preparation.
</details>

<details>
<summary><b>How do I undo changes?</b></summary>
<br>
Open the GUI → Restore tab → select the pre-change snapshot → click Restore. Or via CLI: <code>Restore-WinDebloat7Snapshot -Name "snapshot-name"</code>.
</details>

---

## 🤝 Contributing

We welcome contributions! See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

```powershell
# Clone and run tests
git clone https://github.com/tomytate/Win-Debloat7.git
cd Win-Debloat7
Invoke-Pester -Path tests/Overall.Tests.ps1 -Output Detailed
```

---

<div align="center">

### ⚡ Ready to Reclaim Your PC?

```powershell
iwr -useb https://raw.githubusercontent.com/tomytate/Win-Debloat7/main/setup-standard.ps1 | iex
```

**[📥 Download Latest Release](https://github.com/tomytate/Win-Debloat7/releases) · [📖 Read the Wiki](docs/Home.md) · [💬 Join Discussions](https://github.com/tomytate/Win-Debloat7/discussions) · [🔐 Security Policy](SECURITY.md)**

<br>

Made with ⚡ by **[Tomy Tate](https://github.com/tomytate)** | Licensed under **[MIT](LICENSE)**

*Enjoy a faster, cleaner, more private Windows experience.*

</div>
