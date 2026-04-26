using System;
using System.Diagnostics;
using System.IO;

namespace WinDebloat7
{
    /// <summary>
    /// Note: This executable wrapper is deliberately left unsigned to remain a free, open-source project.
    /// Because of this, Windows 11 Smart App Control (SAC) and Microsoft Defender SmartScreen will
    /// likely block this file. Users must explicitly allow it or disable SAC, or run the .ps1 directly.
    /// </summary>
    class Launcher
    {
        static void Main(string[] args)
        {
            try 
            {
                string scriptName = "Win-Debloat7.ps1";
                string scriptPath = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, scriptName);

                if (!File.Exists(scriptPath))
                {
                    Console.ForegroundColor = ConsoleColor.Red;
                    Console.WriteLine("Error: " + scriptName + " not found in the current directory.");
                    Console.WriteLine("Please ensure the exe is in the same folder as the script.");
                    Console.ReadKey();
                    return;
                }

                // Prepare Process Start Info
                ProcessStartInfo startInfo = new ProcessStartInfo();
                startInfo.FileName = "pwsh.exe";
                startInfo.Arguments = string.Format("-NoProfile -ExecutionPolicy Bypass -File \"{0}\"", scriptPath);
                startInfo.UseShellExecute = true; 

                // If user double clicks, we want a console window. 
                // By default Console app has one.

                try 
                {
                    Process p = Process.Start(startInfo);
                    if (p != null) p.WaitForExit();
                }
                catch (System.ComponentModel.Win32Exception)
                {
                    // pwsh not found
                    Console.ForegroundColor = ConsoleColor.Yellow;
                    Console.WriteLine("PowerShell 7 (pwsh) was not found in your PATH.");
                    Console.WriteLine("Win-Debloat7 requires PowerShell 7.6+.");
                    Console.WriteLine();
                    Console.WriteLine("Press any key to open the download page...");
                    Console.ReadKey();
                    Process.Start(new ProcessStartInfo("https://github.com/PowerShell/PowerShell/releases") { UseShellExecute = true });
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine("An unexpected error occurred: " + ex.Message);
                Console.ReadKey();
            }
        }
    }
}
