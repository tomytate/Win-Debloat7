# Changelog

All notable changes to this project will be documented in this file.

## [1.2.1] - 2026-01-29

### 🚀 New Features
- **Auto-Install Dependency**: The EXE launcher now detects missing PowerShell 7.5 and installs it automatically. No manual prerequisites required.
- **Software Manager**:
  - Added `winget upgrade --all` functionality to update all installed applications.
  - Added **Driver Update Module** with interactive selection (Windows Update, GPU, SDIO).
- **Interactive TUI**: The text-based menu now supports the full Driver Update workflow.

### 🛡️ Improvements
- **Robustness**: The launcher now pauses on errors instead of crashing silently.
- **Version Sync**: Synchronized all modules to v1.2.1.

## [1.2.3] - 2026-01-29
### Fixed
- Version consistency issues across GUI/TUI.
- File lock issues during build process.

## [1.2.0] - 2026-01-25

### 🚀 New Features
- **GUI V2 "Command Center"**:
    - Completely redesigned interface with **5-Tab Navigation**.
    - **System Tweaks**: Consolidated Privacy, Performance, and General settings into one powerful hub.
    - **Dashboard V2**: Modern "Glass" card layout with live RAM/Network metrics.
- **Robust Detection Engine**:
    - Fixed Windows 11 24H2/23H2 detection logic.
    - Expanded **Bloatware Recognition** (Cortana, Maps, Legacy Apps).
    - **Smart RAM**: Now displays Active TCP Connections alongside Memory usage.
- **System Benchmarking**:
    - Generates before/after comparison reports.
- **Hardware-Aware Recommendations**:
    - Intelligent profile suggestion based on RAM/GPU.
- **Dual-Release Distribution**:
    - Automated creation of Standard and Extras packages.

### 🛡️ Safety & Quality
- **Global Unattended Safety**: `-Unattended` mode now forces a snapshot before changes.
- **CI/CD Pipeline**:
    - `ci.yml`: Runs Pester unit tests on every push.
    - `security.yml`: Scans for secrets and security vulnerabilties.
- **Unit Testing**:
    - Standardized on **Pester 5**.
    - Full coverage for Config parsing and System State detection.

## [1.1.0] - 2026-01-23

### 🚀 New Features
- **Premium GUI**: A completely new WPF-based Graphical User Interface (`Press 2` in menu).
    - Dashboard with dynamic **System Health Score**.
    - Real-time status indicators for Telemetry, Copilot, and Recall.
    - Interactive Software installation tab.
- **Cliff Extras (CLI)**:
    - **[9] Defender Remover**: Integrated downloader for the external Defender Remover tool.
    - **[0] Windows Activation**: integrated launcher for Microsoft Activation Scripts (MAS).
- **Microsoft Office 365**: Added to the Software/Productivity list (Official Online Installer).

### ⚡ Improvements
- **PowerShell 7.5 Optimization**:
    - Replaced slow array `+=` operations with `System.Collections.Generic.List[T]` for significant performance gains.
    - Implemented `ConvertTo-CliXml` for robust system snapshots.
- **UI Responsiveness**: Added `Update-GUI` dispatcher helper to prevent "freezing" during long operations.
- **Copilot Detection**: Now checks both HKCU and HKLM registry keys for accurate status reporting.

### 🐛 Bug Fixes
- Fixed "Ambiguous Overload" error in GUI loading logic.
- Fixed Sidebar alignment issues in XAML.
- Fixed Version Detection to properly handle Windows 11 updates (e.g., "24H2").
- Fixed duplicate entries in the software catalog.

### 📦 Dependencies
- **Mandatory Requirement**: PowerShell 7.5+ is now required.
