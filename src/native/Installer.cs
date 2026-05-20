using System;
using System.Diagnostics;
using System.IO;
using System.Reflection;
using System.Runtime.InteropServices;
using System.Windows.Forms;

namespace NetworkTesterSetup
{
    public static class Installer
    {
        private const string AppName = "NetworkTester";

        [STAThread]
        public static void Main()
        {
            try
            {
                string installDir = Path.Combine(
                    Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
                    "Programs",
                    AppName
                );
                string appPath = Path.Combine(installDir, "NetworkTester.exe");

                Directory.CreateDirectory(installDir);
                WriteEmbeddedApp(appPath);
                CreateShortcuts(appPath, installDir);

                MessageBox.Show(
                    "NetworkTester has been installed successfully.",
                    "NetworkTester Setup",
                    MessageBoxButtons.OK,
                    MessageBoxIcon.Information
                );

                Process.Start(appPath);
            }
            catch (Exception ex)
            {
                MessageBox.Show(
                    "Installation failed:\n\n" + ex.Message,
                    "NetworkTester Setup",
                    MessageBoxButtons.OK,
                    MessageBoxIcon.Error
                );
                Environment.Exit(1);
            }
        }

        private static void WriteEmbeddedApp(string appPath)
        {
            Assembly assembly = Assembly.GetExecutingAssembly();
            using (Stream input = assembly.GetManifestResourceStream("NetworkTester.exe"))
            {
                if (input == null)
                {
                    throw new InvalidOperationException("Embedded NetworkTester.exe was not found.");
                }

                using (FileStream output = new FileStream(appPath, FileMode.Create, FileAccess.Write))
                {
                    input.CopyTo(output);
                }
            }

            if (!File.Exists(appPath))
            {
                throw new IOException("NetworkTester.exe was not copied to the install folder.");
            }
        }

        private static void CreateShortcuts(string appPath, string installDir)
        {
            string startMenuDir = Path.Combine(
                Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData),
                "Microsoft",
                "Windows",
                "Start Menu",
                "Programs",
                AppName
            );
            Directory.CreateDirectory(startMenuDir);

            CreateShortcut(Path.Combine(startMenuDir, "NetworkTester.lnk"), appPath, installDir);

            foreach (string desktop in GetDesktopFolders())
            {
                if (Directory.Exists(desktop))
                {
                    CreateShortcut(Path.Combine(desktop, "NetworkTester.lnk"), appPath, installDir);
                }
            }
        }

        private static string[] GetDesktopFolders()
        {
            string normalDesktop = Environment.GetFolderPath(Environment.SpecialFolder.DesktopDirectory);
            string userDesktop = Path.Combine(
                Environment.GetFolderPath(Environment.SpecialFolder.UserProfile),
                "Desktop"
            );
            string oneDriveDesktop = null;
            string oneDrive = Environment.GetEnvironmentVariable("OneDrive");
            if (!string.IsNullOrWhiteSpace(oneDrive))
            {
                oneDriveDesktop = Path.Combine(oneDrive, "Desktop");
            }

            return new string[] { normalDesktop, userDesktop, oneDriveDesktop };
        }

        private static void CreateShortcut(string shortcutPath, string targetPath, string workingDirectory)
        {
            Type shellType = Type.GetTypeFromProgID("WScript.Shell");
            if (shellType == null)
            {
                throw new InvalidOperationException("Windows shortcut service is unavailable.");
            }

            object shell = Activator.CreateInstance(shellType);
            object shortcut = shellType.InvokeMember(
                "CreateShortcut",
                System.Reflection.BindingFlags.InvokeMethod,
                null,
                shell,
                new object[] { shortcutPath }
            );

            Type shortcutType = shortcut.GetType();
            shortcutType.InvokeMember("TargetPath", System.Reflection.BindingFlags.SetProperty, null, shortcut, new object[] { targetPath });
            shortcutType.InvokeMember("WorkingDirectory", System.Reflection.BindingFlags.SetProperty, null, shortcut, new object[] { workingDirectory });
            shortcutType.InvokeMember("IconLocation", System.Reflection.BindingFlags.SetProperty, null, shortcut, new object[] { targetPath });
            shortcutType.InvokeMember("Save", System.Reflection.BindingFlags.InvokeMethod, null, shortcut, null);

            Marshal.FinalReleaseComObject(shortcut);
            Marshal.FinalReleaseComObject(shell);
        }
    }
}
