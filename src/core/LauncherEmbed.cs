using System;
using System.Diagnostics;
using System.IO;
using System.Reflection;

namespace WinDebloat7
{
    class Launcher
    {
        static void Main(string[] args)
        {
            try 
            {
                // 1. Setup Temp Directory
                string tempPath = Path.Combine(Path.GetTempPath(), "WD7_" + Guid.NewGuid().ToString().Substring(0, 8));
                Directory.CreateDirectory(tempPath);
                
                string zipPath = Path.Combine(tempPath, "payload.zip");
                
                // 2. Extract Embedded Resource
                // Note: Resource name must match what CSC uses. Usually just the filename if not namespaced.
                // We will rely on searching for the .zip resource to be safe.
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
                    Console.WriteLine("Error: Embedded payload.zip not found.");
                    return;
                }

                using (Stream stream = assembly.GetManifestResourceStream(resourceName))
                using (FileStream fileStream = new FileStream(zipPath, FileMode.Create))
                {
                    // CopyTo is .NET 4.0+. If we are stuck on .NET 3.5 we need buffer copy.
                    // Assuming .NET 4.5 is available on Win10/11.
                    stream.CopyTo(fileStream);
                }

                // 3. Prepare PowerShell Command
                // We expand the archive, then execute the script, all in one PWSH session.
                // We use -WindowStyle Hidden for the extraction part if possible, but user wants to see progress?
                // Actually, the Script has a GUI/Menu. We should just show the console.
                
                string scriptCmd = string.Format(
                    "$progressPreference='SilentlyContinue'; " +
                    "Write-Host '🚀 Initializing Win-Debloat7...' -ForegroundColor Cyan; " +
                    "Expand-Archive -LiteralPath '{0}' -DestinationPath '{1}' -Force; " +
                    "Set-Location '{1}'; " +
                    "& './Win-Debloat7.ps1';", 
                    zipPath, tempPath
                );

                ProcessStartInfo startInfo = new ProcessStartInfo();
                startInfo.FileName = "pwsh.exe";
                // Encode command to avoid quote escaping hell
                string encodedCmd = Convert.ToBase64String(System.Text.Encoding.Unicode.GetBytes(scriptCmd));
                startInfo.Arguments = "-NoProfile -ExecutionPolicy Bypass -EncodedCommand " + encodedCmd;
                startInfo.UseShellExecute = false;

                // 4. Launch
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
                     Console.WriteLine("Error: PowerShell 7 (pwsh.exe) not found.");
                     Console.WriteLine("Please install PowerShell 7 from https://aka.ms/install-powershell.ps1");
                     Console.ReadKey();
                }

                // 5. Cleanup
                try 
                {
                    Directory.Delete(tempPath, true);
                }
                catch { /* Ignore cleanup errors (file lock, etc) */ }

            }
            catch (Exception ex)
            {
                Console.WriteLine("Launcher Error: " + ex.Message);
                Console.ReadKey();
            }
        }
    }
}
