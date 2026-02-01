using System;
using System.Diagnostics;
using System.IO;
using System.Reflection;
using System.Net;

namespace WinDebloat7
{
    class Launcher
    {
        static void Main(string[] args)
        {
            try 
            {
                // 1. Check for PowerShell 7 (pwsh)
                if (!IsPwshInstalled())
                {
                    Console.ForegroundColor = ConsoleColor.Cyan;
                    Console.WriteLine("⚡ PowerShell 7.5+ not found.");
                    Console.ForegroundColor = ConsoleColor.Green;
                    Console.WriteLine("🚀 Downloading and Installing PowerShell 7 (Auto)...");
                    Console.ResetColor();

                    if (!InstallPowerShell7())
                    {
                        Console.ForegroundColor = ConsoleColor.Red;
                        Console.WriteLine("❌ Failed to install PowerShell 7. Please install manually.");
                        Console.ReadKey();
                        return;
                    }
                    
                    Console.ForegroundColor = ConsoleColor.Green;
                    Console.WriteLine("✅ PowerShell 7 Installed! Launching Win-Debloat7...");
                    Console.ResetColor();
                }

                // 2. Setup Temp Directory
                string tempPath = Path.Combine(Path.GetTempPath(), "WD7_" + Guid.NewGuid().ToString().Substring(0, 8));
                Directory.CreateDirectory(tempPath);
                
                string zipPath = Path.Combine(tempPath, "payload.zip");
                
                // 3. Extract Embedded Resource
                Assembly assembly = Assembly.GetExecutingAssembly();
                string resourceName = null;
                
                foreach (string name in assembly.GetManifestResourceNames())
                {
                    if (name.EndsWith(".zip", StringComparison.OrdinalIgnoreCase))
                    {
                        resourceName = name;
                        break;
                    }
                }

                if (resourceName == null)
                {
                    Console.ForegroundColor = ConsoleColor.Red;
                    Console.WriteLine("Error: Embedded payload.zip not found.");
                    Console.WriteLine("This executable was likely built incorrectly.");
                    Console.ResetColor();
                    Console.ReadKey();
                    return;
                }

                using (Stream stream = assembly.GetManifestResourceStream(resourceName))
                using (FileStream fileStream = new FileStream(zipPath, FileMode.Create))
                {
                    stream.CopyTo(fileStream);
                }

                // 4. Prepare PowerShell Command
                string scriptCmd = string.Format(
                    "$progressPreference='SilentlyContinue'; " +
                    "Write-Host '🚀 Initializing Win-Debloat7...' -ForegroundColor Cyan; " +
                    "Expand-Archive -LiteralPath '{0}' -DestinationPath '{1}' -Force; " +
                    "Set-Location '{1}'; " +
                    "& './Win-Debloat7.ps1';", 
                    zipPath, tempPath
                );

                ProcessStartInfo startInfo = new ProcessStartInfo();
                
                // Try to resolve pwsh path (PATH might be stale after fresh install)
                string pwshPath = "pwsh.exe";
                string defaultInstall = @"C:\Program Files\PowerShell\7\pwsh.exe";
                if (!IsPwshInPath() && File.Exists(defaultInstall))
                {
                    pwshPath = defaultInstall;
                }
                
                startInfo.FileName = pwshPath;
                string encodedCmd = Convert.ToBase64String(System.Text.Encoding.Unicode.GetBytes(scriptCmd));
                startInfo.Arguments = "-NoProfile -ExecutionPolicy Bypass -EncodedCommand " + encodedCmd;
                startInfo.UseShellExecute = false;

                // 5. Launch
                try 
                {
                    Process p = Process.Start(startInfo);
                    if (p != null) 
                    {
                        p.WaitForExit();
                    }
                }
                catch (System.ComponentModel.Win32Exception)
                {
                     Console.ForegroundColor = ConsoleColor.Red;
                     Console.WriteLine("Error: Failed to launch pwsh.exe.");
                     Console.WriteLine("System PATH might not be updated yet.");
                     Console.WriteLine("Tried launching: " + pwshPath);
                     Console.ResetColor();
                     Console.WriteLine("Please restart the application.");
                     Console.ReadKey();
                }

                // 6. Cleanup
                try 
                {
                    Directory.Delete(tempPath, true);
                }
                catch { /* Ignore cleanup errors */ }

            }
            catch (Exception ex)
            {
                Console.ForegroundColor = ConsoleColor.Red;
                Console.WriteLine("Launcher Error: " + ex.Message);
                Console.ResetColor();
                Console.ReadKey();
            }
        }

        static bool IsPwshInPath()
        {
            try {
                Process.Start(new ProcessStartInfo { FileName = "pwsh", Arguments = "-h", UseShellExecute = false, CreateNoWindow = true }).WaitForExit();
                return true;
            } catch { return false; }
        }

        static bool IsPwshInstalled()
        {
            // Check PATH first
            if (IsPwshInPath()) return true;
            
            // Check default location
            if (File.Exists(@"C:\Program Files\PowerShell\7\pwsh.exe")) return true;
            
            return false;
        }

        static bool InstallPowerShell7()
        {
            try
            {
                // Installing via Winget or MSI script
                Console.WriteLine("Downloading installer from Microsoft...");
                
                string installCmd = "Set-ExecutionPolicy Bypass -Scope Process -Force; " +
                                    "[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; " +
                                    "iex '& { $(irm https://aka.ms/install-powershell.ps1) } -UseMSI -Quiet'";

                ProcessStartInfo psi = new ProcessStartInfo
                {
                    FileName = "powershell.exe",
                    Arguments = "-NoProfile -ExecutionPolicy Bypass -Command \"" + installCmd + "\"",
                    UseShellExecute = false,
                    CreateNoWindow = false
                };
                
                Process p = Process.Start(psi);
                p.WaitForExit();
                
                return p.ExitCode == 0;
            }
            catch (Exception ex)
            {
                Console.WriteLine("Install failed: " + ex.Message);
                return false;
            }
        }
    }
}
