# Contributing to Win-Debloat7

Thank you for your interest in improving **Win-Debloat7**! This project has moved to a modular, configuration-driven architecture with a WPF GUI.

## 🛠️ Development Setup
1.  **Requirement**: PowerShell 7.5 or newer is **mandatory**.
2.  **Dependencies**: The project uses `PSResourceGet` to manage dependencies.
3.  **Editor**: VS Code with the PowerShell extension is recommended.

## 📂 Architecture
The code is organized into modules in `src/`:
- **`src/core/`**: Core logic (Logger, Config, State). **Do not modify** unless you are changing the framework itself.
- **`src/modules/`**: Feature modules (Bloatware, Privacy, etc.). **Add new features here.**
- **`src/ui/gui/`**: WPF GUI logic (`GUI.psm1`) and markup (`MainWindow.xaml`).
- **`profiles/`**: YAML configuration files.

## 🚀 How to Add a Feature
1.  **Create a Module**: Create a new folder `src/modules/MyFeature/` and a `.psm1` file.
2.  **Implement Logic**: Write a function `Set-WinDebloat7MyFeature` that accepts a `$Config` object.
    ```powershell
    function Set-WinDebloat7MyFeature {
        param([Object]$Config)
        Write-Log -Message "Doing something..." -Level Info
    }
    ```
3.  **Update Schema**: Add relevant configuration keys to `profiles/schema.yaml` (if applicable).
4.  **Register**: Import your module in `Win-Debloat7.psd1`.

## 🎨 GUI Development
If modifying the GUI:
1.  **XAML**: Edit `src/ui/gui/MainWindow.xaml`. Keep styles consistent with `src/ui/Colors.psm1`.
2.  **Logic**: Edit `src/ui/gui/GUI.psm1`.
3.  **Responsiveness**: Always use the `$updateGui` helper in button handlers to prevent freezing.

## 📝 Code Style
- **Typed Parameters**: Always use `[string]`, `[int]`, `[switch]`, etc.
- **Structured Logging**: Use `Write-Log` instead of `Write-Host`.
- **Classes**: Use PowerShell Classes for complex data structures.
- **Performance**: Use `[System.Collections.Generic.List[T]]` instead of array `+=`.

## ✅ Pull Request Checklist
- [ ] Code runs on PowerShell 7.5.
- [ ] Logic respects the YAML configuration (no hardcoded actions).
- [ ] `Write-Log` is used for all output.
- [ ] GUI changes have been verified to not freeze the UI.
