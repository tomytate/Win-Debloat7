# Features & Capabilities

Win-Debloat7 is modular. You can run the entire suite using a Profile, or use individual modules via the CLI/GUI. Version 1.3.0 includes **92 exported functions** across **28 modules**.

## 🖥️ Dual Interface

### GUI (Graphical)
Launch with `.\Win-Debloat7.ps1` → Option 2 (or no `-NoGui` flag).
- **Dashboard**: Live system metrics (RAM, connections, bloatware count, privacy score).
- **System Tweaks**: One-click toggles for Privacy, Performance, and AI features.
- **Software Manager**: Install essentials, update all apps, manage drivers.
- **Tools**: System repair, network reset, Windows Update fix.
- **Settings**: Dark/Light theme, clipboard history toggle.

### TUI (Terminal)
Launch with `.\Win-Debloat7.ps1 -NoGui`.
- Full-featured interactive menu with 9 numbered options.
- TrueColor terminal rendering (Cyan/Purple neon theme).
- Supports all the same operations as the GUI.

---

## 🛠️ Core Capabilities

### 1. Bloatware Removal
Removes pre-installed Appx packages using O(N) regex matching.
- **Modes**: Conservative, Moderate, Aggressive, Custom
- **Database**: 80+ known bloatware apps (including OEM: HP, Dell, Lenovo, Acer)
- **Advanced**: Full removal of OneDrive, Edge, and Xbox (with service cleanup)
- **Safety**: Profile-based exclusion lists to protect apps you need

### 2. Privacy Hardening
- **Telemetry**: Disables DiagTrack, Connected User Experiences, WaaSMedicSvc
- **Advertising**: Resets Advertising ID, disables Start Menu suggestions
- **AI Suite**: Completely disables Copilot, Recall, Click-to-Do, Notepad AI, Paint AI, Edge AI
- **Hosts Blocking**: Blocks 100+ known telemetry domains via the hosts file
- **Scheduled Tasks**: Disables Microsoft telemetry collection tasks

### 3. Performance Optimization
- **Power Plans**: Unlocks and applies "Ultimate Performance" mode
- **Service Presets**: 4 intelligent presets (Privacy, Performance, Security, Minimal)
- **Gaming Mode**: Disables Nagle's Algorithm, Game DVR/Bar, prioritizes GPU
- **RAM Optimization**: Reduces non-paged pool usage
- **Benchmarking**: Before/after system performance comparison

### 4. Network & DNS
- **DNS Providers**: 12+ options (Cloudflare, Google, Quad9, AdGuard, NextDNS) including Family/Malware variants
- **IPv6 Control**: Toggle IPv6 on/off (with Store compatibility warnings)
- **Network Diagnostics**: Connection status, active connections count

### 5. System Repair (4-Step Sequence)
Industrial-standard repair pipeline:
1. **ChkDsk** — Disk integrity check
2. **SFC /scannow** — System file checker
3. **DISM /RestoreHealth** — Component store repair
4. **SFC /scannow** — Final verification pass

### 6. Software & Driver Management
- **Winget Integration**: Install, update (`--all`), and manage applications
- **Essentials Pack**: One-click install for Chrome, Firefox, Steam, Discord, 7-Zip, VLC
- **Driver Updates**: Windows Update, GPU vendor drivers (NVIDIA/AMD), SDIO support

### 7. UI Customization (Windows 11)
- **Taskbar**: Left/Center alignment
- **Context Menu**: Classic (Win10) or Modern (Win11) style
- **Explorer**: Hide Gallery, Hide Home
- **Start Menu**: Disable Recommended section
- **Ads**: Remove Settings 365 ads, Desktop Spotlight

### 8. Enterprise & OEM (Sysprep)
- **Audit Mode Detection**: Auto-detects Windows Audit Mode
- **Default User Hive**: Apply tweaks to NTUSER.DAT for all future user profiles
- **Headless Deployment**: `-Profile config.yaml -Unattended` for RMM tools

### 9. Third-Party Integrations
- **ShutUp10++**: O&O privacy tool wrapper
- **AdwCleaner**: Malwarebytes adware scanner
- **SDIO**: Snappy Driver Installer Origin for offline/legacy drivers

---

## 🛡️ Safety Architecture

### Encrypted Snapshots
- **Technology**: `ConvertTo-CliXml` with Windows DPAPI encryption
- **Frequency**: Bypasses the "1 restore point per 24h" limit
- **Restoration**: One-click rollback from the GUI Restore tab

### Non-Destructive Defaults
The Standard edition will never touch critical components (Store, Windows Update) unless explicitly configured in your YAML profile.

### Audit Trail
All actions are logged to `C:\ProgramData\Win-Debloat7\Logs` with structured timestamps and severity levels.
