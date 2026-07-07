# About Win-Debloat7

## 📖 Description
**Win-Debloat7** is a professional-grade Windows 10/11 optimization framework tailored for power users, gamers, and system administrators. It streamlines the removal of pre-installed bloatware, hardens system privacy by disabling invasive telemetry, and tunes performance settings—all while prioritizing **safety** and **reversibility** via encrypted snapshots.

## 🛡️ The Philosophy
Win-Debloat7 was born from a simple frustration: Windows optimization scripts are often **opaque**, **destructive**, and **outdated**.

We built Win-Debloat7 to be the **"Gold Standard"**:
1.  **Transparency**: Every tweak is visible in the code. No compiled binaries (in Standard edition).
2.  **Safety**: We use official Microsoft APIs (PowerShell, DISM, Group Policy) rather than hacking registry keys blindly.
3.  **Modernity**: Built strictly for **PowerShell 7.6+**, leveraging `clean` blocks, parallel loops, and improved security.
4.  **Performance**: O(N) regex-based processing, O(1) batch service queries, and modern collection handling.

## 📊 v1.3.1 at a Glance
- **29** registered modules
- **115** exported functions
- Pester compliance suite + PSScriptAnalyzer enforced in CI
- **0** PSScriptAnalyzer errors
- **11** DNS providers
- **139** bloatware apps (tiered removal)
- **5** service optimization presets

## 👥 The Team
**Lead Maintainer:** [Tomy Tate](https://github.com/tomytate)

## 📜 License
Win-Debloat7 is open-source software licensed under the **MIT License**.
You are free to use, modify, and distribute it, provided you give credit to the original authors.

## 🏗️ Tech Stack
*   **Language**: PowerShell 7.6+
*   **GUI**: Windows Presentation Foundation (WPF) / XAML
*   **TUI**: TrueColor terminal rendering (24-bit ANSI)
*   **Config**: YAML profiles with schema validation
*   **Testing**: Pester 5 + PSScriptAnalyzer
*   **Build**: Single-file EXE via PS2EXE, Dual-Release architecture
*   **Distribution**: GitHub Releases, Chocolatey

## 🌟 Acknowledgements
Special thanks to the open-source community, specifically contributions from:
*   *LeDragoX* (Optimization research)
*   *Massgravel* (MAS integration ideas)
