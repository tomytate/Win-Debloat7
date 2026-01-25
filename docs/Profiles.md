# Profile Configuration Guide

Win-Debloat7 uses **YAML configuration files** (`.yaml`) to define optimization states. This approach allows for version-controlled, repeatable, and shareable system setups.

## 📂 Profile Location

Default profiles are stored in the `profiles/` directory:
- `conservative.yaml`: Minimal changes.
- `moderate.yaml`: Balanced (Recommended).
- `gaming.yaml`: Aggressive performance tuning.

## 📝 YAML Schema

A profile consists of several sections. Here is the full breakdown.

### 1. Metadata
Information about the profile itself.
```yaml
metadata:
  name: "My Custom Profile"
  author: "TomyTate"
  description: "Optimization for high-end gaming PC"
  version: "1.0"
```

### 2. Bloatware
Controls removal of pre-installed Appx packages.

```yaml
bloatware:
  # Mode: 'Conservative', 'Moderate', 'Aggressive', or 'None'
  removal_mode: "Moderate"
  
  # List of package names to KEEP (supports wildcards)
  exclude_list:
    - "Microsoft.WindowsStore"
    - "Microsoft.WindowsCalculator"
    - "*Xbox*"
```

### 3. Privacy
Controls telemetry and data collection settings.

```yaml
privacy:
  # Level: 'Basic' (Standard) or 'Security' (Strict)
  telemetry_level: "Security"
  
  disable_copilot: true   # Windows 11 AI assistant
  disable_recall: true    # Windows 11 Recall feature
  disable_advertising_id: true
  disable_location: false # Set true to block location services
```

### 4. Performance
System tuning parameters.

```yaml
performance:
  # Power Plan: 'Balanced', 'High Performance', 'Ultimate'
  power_plan: "Ultimate"
  
  disable_game_dvr: true         # Xbox Game Bar recording
  disable_background_apps: true  # Prevents apps running in background
  optimize_ram: true             # Reduce non-paged pool usage
```

### 5. Taskbar (Customization)
UI preference automations.

```yaml
taskbar:
  # Alignment: 'Left' or 'Center' (Win11 only)
  alignment: "Left"
  
  # Search Icon: 'Hidden', 'Icon', 'Box'
  search_mode: "Icon"
  
  hide_widgets: true
  hide_chat: true
```

## 🛠️ How to Create a Custom Profile

1.  Copy an existing profile (e.g., `profiles\moderate.yaml`).
2.  Rename it to `my-profile.yaml`.
3.  Edit the values in any text editor (Notepad, VS Code).
4.  Run it:
    ```powershell
    .\Win-Debloat7.ps1 -ProfileFile "profiles\my-profile.yaml"
    ```
