<div align="center">

<img src="assets/logo.png" alt="Win-Debloat7" width="140" height="140">

# Win-Debloat7

### The Professional Windows 10 & 11 Debloater, Optimizer & Privacy Hardener

**Remove bloatware. Kill telemetry. Maximize performance. One command.**

[![Release](https://img.shields.io/github/v/release/tomytate/Win-Debloat7?style=for-the-badge&color=00D9FF&label=v1.3.0)](https://github.com/tomytate/Win-Debloat7/releases)
[![Downloads](https://img.shields.io/github/downloads/tomytate/Win-Debloat7/total?style=for-the-badge&color=00D9FF&label=Downloads)](https://github.com/tomytate/Win-Debloat7/releases)
[![Stars](https://img.shields.io/github/stars/tomytate/Win-Debloat7?style=for-the-badge&color=00D9FF)](https://github.com/tomytate/Win-Debloat7/stargazers)
[![License](https://img.shields.io/badge/License-MIT-00D9FF?style=for-the-badge)](LICENSE)
[![PowerShell](https://img.shields.io/badge/PowerShell-7.6+-00D9FF?style=for-the-badge&logo=powershell)](https://github.com/PowerShell/PowerShell/releases)
[![Tests](https://img.shields.io/badge/Pester-35%2F35_Passed-00FF88?style=for-the-badge)](tests/)

**[⚡ Quick Install](#-quick-install) · [📖 Features](#-features-overview) · [🏗️ Profiles](docs/Profiles.md) · [📚 Wiki](docs/Home.md) · [🐛 Report Bug](https://github.com/tomytate/Win-Debloat7/issues)**

</div>

---

<p align="center">
  <img src="assets/ss-dashboard.png" alt="Win-Debloat7 WPF Dashboard" width="860">
</p>

---

## 📋 Table of Contents

- [What is Win-Debloat7?](#-what-is-win-debloat7)
- [Key Stats](#key-stats-v130)
- [Quick Install](#-quick-install)
- [Features Overview](#-features-overview)
- [Bloatware Removal](#-bloatware-removal)
- [Privacy & AI Disablement](#-privacy--ai-disablement)
- [Performance Optimization](#-performance-optimization)
- [Network & DNS Configuration](#-network--dns-configuration)
- [Windows 11 UI Customization](#-windows-11-ui-customization)
- [Enterprise Deployment & Sysprep](#-enterprise-deployment--sysprep)
- [Safety & Encrypted Rollback](#-safety--encrypted-rollback)
- [Why Win-Debloat7?](#-why-win-debloat7-vs-alternatives)
- [Trust & Verification](#-trust--verification)
- [FAQ](#-frequently-asked-questions)
- [Contributing](#-contributing)

---

## ⚡ What is Win-Debloat7?

**Win-Debloat7** is a professional-grade, open-source Windows debloating and optimization framework. It removes pre-installed bloatware, disables invasive telemetry and AI features, optimizes system performance, and hardens privacy — all with **one-click rollback** via DPAPI-encrypted snapshots.

Unlike legacy debloat scripts that blindly delete registry keys, Win-Debloat7 treats your system configuration **as code**. It uses audit-friendly YAML profiles, creates encrypted snapshots before every change, and exports structured logs for full transparency.

> **"It's like `terraform apply` for your Windows PC."**

### Key Stats (v1.3.0)

| Metric | Value |
|--------|-------|
| **Version** | 1.3.0 |
| **Modules** | 28 registered |
| **Functions** | 91 exported (Standard edition) |
| **Bloatware Patterns** | 80+ apps detected |
| **DNS Providers** | 10 (Standard, Security & Family variants) |
| **Service Presets** | 4 intelligent profiles |
| **Test Coverage** | 35/35 Pester tests passed |
| **PSScriptAnalyzer** | 0 errors |
| **Windows Support** | 10 (22H2+) and 11 (through 25H2) |

---

## 🚀 Quick Install

Open **PowerShell as Administrator** and run one command:

### Option A — Standard Edition (Recommended) 🛡️

Clean, open-source, zero AV warnings.

```powershell
iwr -useb https://raw.githubusercontent.com/tomytate/Win-Debloat7/main/setup-standard.ps1 | iex
```

### Option B — Extras Edition (Advanced) ⚠️

Includes **Defender Remover** and **MAS**. Antivirus warnings are expected.

```powershell
iwr -useb https://raw.githubusercontent.com/tomytate/Win-Debloat7/main/setup-extras.ps1 | iex
```

<details>
<summary><b>📥 Alternative: Download Single-File EXE</b></summary>
<br>

1. Go to the **[Releases Page](https://github.com/tomytate/Win-Debloat7/releases)**.
2. Download **Win-Debloat7.exe** (Standard) or **Win-Debloat7-Extras.exe** (Extras).
3. Right-click → **Run as Administrator**.
4. The launcher auto-installs PowerShell 7.6 if missing.
</details>

<details>
<summary><b>🍫 Alternative: Chocolatey</b></summary>
<br>

```powershell
choco install win-debloat7
```
</details>

<details>
<summary><b>🛠️ Alternative: Clone from Source</b></summary>
<br>

```powershell
git clone https://github.com/tomytate/Win-Debloat7.git
cd Win-Debloat7
.\Win-Debloat7.ps1
```
</details>

**Requirements:** Windows 10 (22H2+) or Windows 11 · PowerShell 7.6+ · Administrator privileges

---

## 📖 Features Overview

Win-Debloat7 ships **91 exported functions** across **28 modules**, organized into 9 feature areas:

| Feature Area | Description | Primary Function |
|---|---|---|
| 🧹 **Bloatware Removal** | Remove 80+ pre-installed apps with O(N) regex matching | `Remove-WinDebloat7Bloatware` |
| 🔒 **Privacy Hardening** | Disable telemetry, block tracking domains via hosts | `Set-WinDebloat7Privacy` |
| 🤖 **AI Disablement** | Neutralize Copilot, Recall, Click-to-Do and more | `Disable-WinDebloat7AIRecall` |
| ⚡ **Performance Tuning** | Ultimate power plan, intelligent service presets | `Set-WinDebloat7Performance` |
| 🌐 **Network & DNS** | 10 verified DNS providers, IPv6 toggle | `Set-WinDebloat7DNS` |
| 🎮 **Gaming Mode** | Nagle's algorithm, Game DVR, GPU priority | `Set-WinDebloat7Gaming` |
| 🖥️ **UI Customization** | Taskbar, context menu, Start Menu tweaks | `Set-WinDebloat7TaskbarAlignment` |
| 🔧 **System Repair** | 4-step industrial repair (ChkDsk → SFC → DISM → SFC) | `Repair-WinDebloat7System` |
| 🏢 **Enterprise Sysprep** | OEM image deployment, headless unattended mode | `Invoke-WinDebloat7SysprepDefaults` |

---

## 🧹 Bloatware Removal

Removes pre-installed Appx packages using **O(N) regex matching** — 50x faster than legacy nested-loop approaches.

### What Gets Removed

| Category | Examples |
|----------|---------|
| **Social Media** | Facebook, Instagram, Twitter/X, TikTok, LinkedIn |
| **Streaming** | Spotify, Netflix, Disney+, Prime Video, Pandora |
| **Casual Games** | Candy Crush, Bubble Witch, FarmVille, March of Empires |
| **Microsoft Bloat** | Get Started, Tips, Feedback Hub, Mixed Reality Portal, News |
| **OEM Bloatware** | HP Support Assistant, Dell SupportAssist, Lenovo Vantage, Acer Care Center |

### Removal Modes

| Mode | Scope |
|------|---------|
| **Conservative** | Only sponsored / promo apps |
| **Moderate** | Non-essential Microsoft apps *(recommended)* |
| **Aggressive** | Everything except Store and Calculator |
| **Custom** | Define your own list via YAML profile |

### Advanced Removal

- **OneDrive** — Complete nuclear removal, all registry traces cleared
- **Microsoft Edge** — Force uninstall with WebView2 preserved
- **Xbox** — Apps + background services + Game Bar

---

## 🔒 Privacy & AI Disablement

### Telemetry Blocking

- **DiagTrack** service disabled (Connected User Experiences & Telemetry)
- **WaaSMedicSvc** neutralized
- **100+ telemetry domains** blocked via hosts file
- **Advertising ID** reset and disabled
- **Telemetry scheduled tasks** disabled via `Disable-WinDebloat7TelemetryTasks`

### Windows AI Disablement Suite

Completely neutralizes Microsoft’s AI features introduced in Windows 11 22H2–25H2:

| AI Feature | Disable Method | Function |
|---|---|---|
| **Windows Recall** | Group Policy + Service kill | `Disable-WinDebloat7AIRecall` |
| **Copilot** | Taskbar removal + Policy + Win+C key | `Disable-WinDebloat7Copilot` |
| **Click-to-Do** | Registry override | `Disable-WinDebloat7ClickToDo` |
| **Notepad AI** | Feature flag | `Disable-WinDebloat7NotepadAI` |
| **Paint AI** | Feature flag | `Disable-WinDebloat7PaintAI` |
| **Edge AI** | Policy override | `Disable-WinDebloat7EdgeAI` |

---

## ⚡ Performance Optimization

### Power Management

- **Ultimate Performance** — Unlock and activate the hidden power plan (`Enable-WinDebloat7UltimatePower`)
- **Plan Duplication** — Clone the plan for custom modifications

### Service Optimization

4 intelligent presets driven by `config/services.json`:

| Preset | Purpose | Affected Services |
|--------|---------|-------------------|
| **Privacy** | Disable telemetry services | DiagTrack, dmwappushservice, WaaSMedicSvc |
| **Performance** | Disable background services | SysMain, WSearch, Fax, PrintWorkflow |
| **Security** | Harden attack surface | RemoteRegistry, SMB1, NetBIOS |
| **Minimal** | Bare essentials only | Combined Privacy + Performance |

### Gaming Tweaks

- Disable **Nagle's Algorithm** (TCPNoDelay = 1)
- Optimize **MMCSS Scheduling** (SystemResponsiveness = 0)
- Disable **Game DVR / Game Bar** background recording
- GPU task **priority elevation**
- **Network latency** tuning for competitive play

---

## 🌐 Network & DNS Configuration

Switch your DNS provider in one command. Full database stored in `config/dns.json`.

| Provider | Primary | Secondary | Type |
|---|---|---|---|
| **Cloudflare** | 1.1.1.1 | 1.0.0.1 | Standard |
| **Cloudflare Malware** | 1.1.1.2 | 1.0.0.2 | Security |
| **Cloudflare Family** | 1.1.1.3 | 1.0.0.3 | Family Safe |
| **Google** | 8.8.8.8 | 8.8.4.4 | Standard |
| **OpenDNS** | 208.67.222.222 | 208.67.220.220 | Standard (Cisco) |
| **Quad9** | 9.9.9.9 | 149.112.112.112 | Security |
| **AdGuard** | 94.140.14.14 | 94.140.15.15 | Ad Blocking |
| **AdGuard Family** | 94.140.14.15 | 94.140.15.16 | Family Safe |
| **CleanBrowsing Security** | 185.228.168.9 | 185.228.169.9 | Security |
| **CleanBrowsing Family** | 185.228.168.168 | 185.228.169.168 | Family Safe |

```powershell
# Set a provider
Set-WinDebloat7DNS -Provider Cloudflare
Set-WinDebloat7DNS -Provider OpenDNS
Set-WinDebloat7DNS -Provider AdGuard

# Set custom DNS servers
Set-WinDebloat7DNS -Provider Custom -CustomPrimary "1.2.3.4" -CustomSecondary "5.6.7.8"

# Disable IPv6
Disable-WinDebloat7IPv6
```

---

## 🖥️ Windows 11 UI Customization

| Tweak | Function | Options |
|-------|----------|---------|
| **Taskbar Alignment** | `Set-WinDebloat7TaskbarAlignment` | Left, Center |
| **Context Menu** | `Set-WinDebloat7ContextMenu` | Classic (Win10 style), Modern (Win11 style) |
| **File Explorer** | `Set-WinDebloat7Explorer` | Hide Gallery, Hide Home |
| **Start Menu** | `Set-WinDebloat7StartMenu` | Disable Recommended section |
| **Desktop Ads** | `Disable-WinDebloat7DesktopSpotlight` | Remove Windows Spotlight ads |
| **Settings Ads** | `Disable-WinDebloat7Settings365Ads` | Remove Microsoft 365 promotions |

---

## 🏢 Enterprise Deployment & Sysprep

Deploy Win-Debloat7 at scale using **configuration-as-code** YAML profiles:

```yaml
# corporate-baseline.yaml
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
  services_preset: "Performance"
```

```powershell
# Headless deployment (Intune, SCCM, PDQ, or any RMM)
.\Win-Debloat7.exe -Profile corporate-baseline.yaml -Unattended
```

### Sysprep / OEM Image Support

Apply tweaks to the **Default User** registry hive so all future user profiles inherit the settings:

```powershell
Invoke-WinDebloat7SysprepDefaults
```

---

## 🛡️ Safety & Encrypted Rollback

Win-Debloat7 is built with enterprise-grade safety rails:

| Safety Feature | Description |
|---|---|
| **DPAPI-Encrypted Snapshots** | Full system state backup before every change |
| **One-Click Rollback** | Restore exact registry + service state from the GUI |
| **Bypass 24h Limit** | Creates snapshots without the Windows "1 per day" restriction |
| **Non-Destructive Default** | Standard edition never touches Windows Update or Store unless explicitly configured |
| **Structured Logs** | Every action logged to `C:\ProgramData\Win-Debloat7\Logs` |
| **Pester Verified** | 35/35 compliance tests pass on every release build |

```powershell
# Create a named snapshot manually
New-WinDebloat7Snapshot -Name "before-cleanup"

# Restore from snapshot
Restore-WinDebloat7Snapshot -Name "before-cleanup"

# List all snapshots
Get-WinDebloat7Snapshot
```

---

## 🏆 Why Win-Debloat7 vs Alternatives?

| Feature | Win-Debloat7 | Chris Titus WinUtil | O&O ShutUp10 | Sophia Script |
|---|:---:|:---:|:---:|:---:|
| **Open Source** | ✅ MIT | ✅ MIT | ❌ Proprietary | ✅ MIT |
| **Config as Code (YAML)** | ✅ | ❌ | ❌ | ❌ |
| **DPAPI Encrypted Rollback** | ✅ | ❌ | ⚠️ Manual | ⚠️ Manual |
| **AI Disablement Suite (6 features)** | ✅ | ⚠️ Partial | ⚠️ Partial | ⚠️ Partial |
| **Service Presets (JSON-driven)** | ✅ 4 presets | ❌ | ❌ | ❌ |
| **Hardware Detection** | ✅ RAM/CPU/GPU | ❌ | ❌ | ❌ |
| **GUI + TUI** | ✅ Both | ✅ GUI | ✅ GUI | ❌ CLI only |
| **Sysprep / OEM Deploy** | ✅ | ❌ | ❌ | ❌ |
| **Unattended Mode** | ✅ | ⚠️ Limited | ❌ | ⚠️ Limited |
| **DNS Management (10 providers)** | ✅ | ❌ | ❌ | ❌ |
| **PSScriptAnalyzer Clean** | ✅ 0 errors | — | — | — |

---

## 🔒 Trust & Verification

### Before Running Any Debloat Tool (Including Ours)

1. ✅ **Verify the source** — only download from [github.com/tomytate/Win-Debloat7/releases](https://github.com/tomytate/Win-Debloat7/releases)
2. ✅ **Check SHA256 hashes** — every release includes checksums in its Release Notes
3. ✅ **Understand Standard vs Extras**:
   - **Standard** (`Win-Debloat7.exe`) — clean PowerShell code, no AV warnings
   - **Extras** (`Win-Debloat7-Extras.exe`) — includes Defender Remover + MAS → **expected** AV flags

### Transparency Promise

- 🔓 **100% Open Source** — no compiled binaries in the Standard edition
- 📋 **Structured Logs** — every action logged with timestamps and severity
- 🔐 **Encrypted Snapshots** — rollback state stored with Windows DPAPI
- 🧪 **Verified** — 35/35 Pester tests + 0 PSScriptAnalyzer errors on every release

> If the Standard Edition triggers AV warnings, [report it immediately](https://github.com/tomytate/Win-Debloat7/issues) as a false positive.

---

## ❓ Frequently Asked Questions

<details>
<summary><b>Is Win-Debloat7 safe to use?</b></summary>
<br>
Yes. The Standard edition uses only official PowerShell APIs and Group Policy modifications. Every change creates an encrypted DPAPI snapshot for instant rollback. The codebase passes 35/35 Pester compliance tests and has 0 PSScriptAnalyzer errors.
</details>

<details>
<summary><b>Will this break Windows Update or Microsoft Store?</b></summary>
<br>
No, not with default settings. The Standard edition never touches Windows Update or Microsoft Store unless you explicitly configure it in your YAML profile. Aggressive bloatware removal may affect Store components — use snapshot rollback to restore.
</details>

<details>
<summary><b>Why does the Extras edition trigger my antivirus?</b></summary>
<br>
The Extras edition includes <b>Defender Remover</b> and <b>MAS</b> (Microsoft Activation Scripts). These tools modify Windows security components and are intentionally flagged as "HackTools" by AV software. This is expected behavior. Use the Standard edition for zero AV warnings.
</details>

<details>
<summary><b>Does Win-Debloat7 work on Windows 10?</b></summary>
<br>
Yes. Win-Debloat7 supports Windows 10 (22H2+) and Windows 11 (all versions through 25H2). Some features (AI disablement, Taskbar alignment, Recall) are Windows 11–specific and are skipped gracefully on Windows 10.
</details>

<details>
<summary><b>Can I use this for enterprise / Intune / SCCM deployment?</b></summary>
<br>
Yes. Use <code>-Profile config.yaml -Unattended</code> for headless deployment via any RMM. The Sysprep module (<code>Invoke-WinDebloat7SysprepDefaults</code>) applies tweaks to the Default User hive for OEM image preparation.
</details>

<details>
<summary><b>How do I undo all changes?</b></summary>
<br>
GUI: Restore tab → select snapshot → click Restore.<br>
CLI: <code>Restore-WinDebloat7Snapshot -Name "snapshot-name"</code>
</details>

---

## 🤝 Contributing

Contributions are welcome! See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

```powershell
# Clone and run the full test suite
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

**[📥 Download Latest Release](https://github.com/tomytate/Win-Debloat7/releases) · [📖 Read the Wiki](docs/Home.md) · [💬 Discussions](https://github.com/tomytate/Win-Debloat7/discussions) · [🔐 Security Policy](SECURITY.md)**

<br>

Made with ⚡ by **[Tomy Tate](https://github.com/tomytate)** · Licensed under **[MIT](LICENSE)**

*Enjoy a faster, cleaner, more private Windows experience.*

</div>
