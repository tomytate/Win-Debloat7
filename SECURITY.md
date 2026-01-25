# Security Policy

## Supported Versions

Only the latest major version is actively supported.

| Version | Supported          |
| ------- | ------------------ |
| 1.2.x   | :white_check_mark: |
| 1.1.x   | :x:                |
| < 1.0   | :x:                |

## 🚨 Antivirus & False Positives

**Win-Debloat7-Extras.exe** contains third-party tools (Defender Remover, MAS) that are **intentionally flagged** by Antivirus software as "HackTool" or "PUP" (Potentially Unwanted Program).

*   **This is expected behavior.** These tools modify Windows activation or security components.
*   **Standard Edition (`Win-Debloat7.exe`)** is guaranteed to be clean and should **NOT** trigger any warnings.

If you encounter a virus warning:
1.  Verify you are using the **Standard Edition** if you want a clean experience.
2.  Verify the SHA256 Checksum against the one published in the Release Notes.
3.  If the **Standard Edition** triggers a warning, please report it immediately as a False Positive.

## Reporting a Vulnerability

We take the security of **Win-Debloat7** seriously. If you discover a security vulnerability in the distinct codebase (e.g., in the PowerShell logic, GUI, or API handling):

1.  **Do NOT open a public issue.**
2.  Use the [GitHub Security Advisory](https://github.com/tomytate/Win-Debloat7/security/advisories/new) feature to report it privately.
3.  Provide steps to reproduce the issue.

## Supply Chain Security

*   Releases are built via **GitHub Actions** (CI/CD) to ensure code integrity.
*   We use **SHA256 checksums** for all release artifacts. Always verify these before running.

## Safe Usage

*   Always download releases from the official [GitHub Releases](https://github.com/tomytate/Win-Debloat7/releases) page.
*   Avoid downloading from third-party sites.
*   Use "Standard" edition for Enterprise/Production environments.
