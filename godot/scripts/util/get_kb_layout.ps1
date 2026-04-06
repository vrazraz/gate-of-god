Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public class KBLayout {
    [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
    [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h, out uint p);
    [DllImport("user32.dll")] public static extern IntPtr GetKeyboardLayout(uint t);
}
"@ -ErrorAction SilentlyContinue
$w = [KBLayout]::GetForegroundWindow()
$p = 0
$t = [KBLayout]::GetWindowThreadProcessId($w, [ref]$p)
$l = [KBLayout]::GetKeyboardLayout($t)
$id = $l.ToInt64() -band 0xFFFF
Write-Host ("{0:X4}" -f $id) -NoNewline
