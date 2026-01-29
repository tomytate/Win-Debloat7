# Contributing to Win-Debloat7

Thank you for your interest in contributing to **Win-Debloat7**! We welcome improvements, bug fixes, and new features.

## 🤝 Code of Conduct
Please be respectful and inclusive. We prioritize safety and transparency in all code changes.

## 🛠️ Development Setup
1. **Prerequisites**:
   - Windows 10/11
   - PowerShell 7.5+
   - VS Code (Recommended) with PowerShell extension

2. **Clone the repo**:
   ```powershell
   git clone https://github.com/tomytate/Win-Debloat7.git
   cd Win-Debloat7
   ```

3. **Run Locally**:
   ```powershell
   ./Win-Debloat7.ps1 -NoGui
   ```

## 🧪 Testing
- We use **Pester 5** for unit testing.
- Run tests before submitting a PR:
  ```powershell
  Invoke-Pester -Path tests/Unit -Output Detailed
  ```

## 📦 Project Structure
- `src/core`: Core logic (Logging, Config, State)
- `src/modules`: Individual features (Bloatware, Privacy, Performance)
- `src/ui`: GUI and Menu systems
- `profiles`: YAML configuration files

## 📝 Pull Request Guidelines
1. **One feature per PR**: Keep changes focused.
2. **Descriptive Title**: e.g., "Add Firefox Telemetry Blocking".
3. **Verify Safety**: Ensure no critical system components (like Bootloader) are touched.
4. **Update Documentation**: If you change functionality, update `README.md`.

## ⚠️ "Extras" Build Variant
- Code related to **Defender Remover** or **MAS** is located in `src/modules/Extras`.
- The build script (`build/Build-DualRelease.ps1`) automatically handles the inclusion/exclusion of these modules.
- Do **NOT** commit compiled EXEs or large binaries to the repository.

Thank you for helping build the Gold Standard of Windows Optimization!
