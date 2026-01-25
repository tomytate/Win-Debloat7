# Publishing Guide for Win-Debloat7

This guide explains how to publish the `v1.2.0` release to **Chocolatey** and **Winget** using the automatically generated manifests.

> **Note:** The `Build-DualRelease.ps1` script automatically updates these manifests with the correct Version, URL, and SHA256 checksum whenever you build.

---

## 🍫 Chocolatey

### Prerequisites
1.  Create an account on [Chocolatey.org](https://chocolatey.org/).
2.  Get your API Key from your profile.
3.  Install Chocolatey locally.

### Publishing Steps

1.  **Open PowerShell** in the project directory.
2.  **Pack** the NuSpec file:
    ```powershell
    choco pack build/chocolatey/Win-Debloat7.nuspec
    ```
    *This creates a `win-debloat7.1.2.0.nupkg` file.*

3.  **Set API Key** (One time only):
    ```powershell
    choco apikey --key "YOUR_API_KEY_HERE" --source https://push.chocolatey.org/
    ```

4.  **Push** the package:
    ```powershell
    choco push win-debloat7.1.2.0.nupkg --source https://push.chocolatey.org/
    ```

5.  **Status:** It will go through automated validation and human moderation (takes 1-5 days).

---

## 📦 Winget (Windows Package Manager)

### Prerequisites
1.  A GitHub account.
2.  Fork the [microsoft/winget-pkgs](https://github.com/microsoft/winget-pkgs) repository.

### Publishing Steps

1.  **Locate the Manifest:**
    The build script generated a valid singleton manifest at:  
    `build/winget/Win-Debloat7.yaml`

2.  **Create Directory Structure:**
    In your forked `winget-pkgs` repo, create this path:
    `manifests/t/TomyTolledo/WinDebloat7/1.2.0/`

3.  **Copy the Manifest:**
    Copy `build/winget/Win-Debloat7.yaml` to that directory.

4.  **Submit Pull Request:**
    *   Commit changes to your fork.
    *   Open a Pull Request to `microsoft/winget-pkgs`.
    *   Title: `New version: TomyTolledo.WinDebloat7 version 1.2.0`
    *   The Winget bot will validate it automatically.

---

## 🛠️ Validation (Test Locally)

Before pushing, you can test the manifests locally.

**Chocolatey Test:**
```powershell
choco install win-debloat7 --source ".;https://community.chocolatey.org/api/v2/"
```

**Winget Test:**
```powershell
winget install --manifest "build/winget/Win-Debloat7.yaml"
```
