# 📦 How to Submit Win-Debloat7 to Winget

Follow these steps exactly to publish your app to the Windows Package Manager.

## Phase 1: Forking (Web)

1.  Open your browser to: **[https://github.com/microsoft/winget-pkgs](https://github.com/microsoft/winget-pkgs)**
2.  Look at the top-right corner of the page.
3.  Click the button labeled **Run Fork** (or just **Fork**).
4.  Select your account (`tomytate` or similar).
5.  Wait a few seconds until you land on *your* version of the repository (`github.com/YOUR_USER/winget-pkgs`).
6.  Click the green **Code** button and copy the HTTPS URL (e.g., `https://github.com/tomytate/winget-pkgs.git`).

---

## Phase 2: Cloning (Local)

1.  Open your PowerShell terminal.
2.  Go to your documents folder (or wherever you want to put the repo):
    ```powershell
    cd "$home\Documents"
    ```
3.  Clone your new fork (replace URL with the one you copied):
    ```powershell
    git clone https://github.com/YOUR_USERNAME/winget-pkgs.git
    ```
4.  Enter the directory:
    ```powershell
    cd winget-pkgs
    ```

---

## Phase 3: Copying the Manifest

I have already prepared the correct folder structure for you. You just need to copy it into your winget repo.

Run this command (assuming you are still in `winget-pkgs` and `Win-Debloat7` is next door):

```powershell
# Create the directory structure in your winget repo
$dest = "manifests\t\TomyTolledo\WinDebloat7\1.2.0"
New-Item -Path $dest -ItemType Directory -Force

# Copy the file FROM your Win-Debloat7 project TO here
Copy-Item "..\Win-Debloat7\build\winget\Win-Debloat7.yaml" -Destination "$dest\Win-Debloat7.yaml"
```

---

## Phase 4: Submitting (Git)

Now we send the changes back to GitHub.

1.  Create a new branch (good practice):
    ```powershell
    git checkout -b win-debloat7-1.2.0
    ```
2.  Add the files:
    ```powershell
    git add .
    ```
3.  Commit the changes:
    ```powershell
    git commit -m "New version: TomyTolledo.WinDebloat7 version 1.2.0"
    ```
4.  Push to your fork:
    ```powershell
    git push origin win-debloat7-1.2.0
    ```

---

## Phase 5: Pull Request (Web)

1.  Go back to your GitHub fork (`github.com/YOUR_USER/winget-pkgs`).
2.  You should see a yellow banner: **"win-debloat7-1.2.0 had recent pushes"**.
3.  Click the green **Compare & pull request** button.
4.  Ensure the title is: `New version: TomyTolledo.WinDebloat7 version 1.2.0`
5.  Check the boxes in the checklist provided in the text box.
6.  Click **Create pull request**.

🎉 **Done!** The Microsoft Winget bot will now automatically check your submission. If it passes, it will be merged, and users can install your app via `winget install Win-Debloat7`.
