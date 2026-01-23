# Changelog

All notable changes to this project will be documented in this file.

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
