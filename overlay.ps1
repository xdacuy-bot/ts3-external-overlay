Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type @"
using System; using System.Runtime.InteropServices;
public static class OWin {
 [DllImport("user32.dll")] public static extern int GetWindowLong(IntPtr h,int n);
 [DllImport("user32.dll")] public static extern int SetWindowLong(IntPtr h,int n,int v);
 [DllImport("user32.dll")] public static extern bool SetWindowDisplayAffinity(IntPtr h,uint a);
 public const int GWL_EXSTYLE=-20, WS_EX_TRANSPARENT=0x20, WS_EX_TOOLWINDOW=0x80, WS_EX_NOACTIVATE=0x08000000;
 public const uint WDA_EXCLUDEFROMCAPTURE=0x11;
}
"@
$dir=Join-Path $env:APPDATA 'TS3ExternalOverlay'; New-Item -ItemType Directory -Force $dir|Out-Null
$file=Join-Path $dir 'talkers.txt'; if(!(Test-Path $file)){''|Set-Content -Encoding UTF8 $file}
$form=New-Object Windows.Forms.Form; $form.FormBorderStyle='None';$form.ShowInTaskbar=$false;$form.TopMost=$true;$form.StartPosition='Manual';$form.Location=New-Object Drawing.Point(20,220);$form.Size=New-Object Drawing.Size(600,400)
$key=[Drawing.Color]::FromArgb(1,2,3);$form.BackColor=$key;$form.TransparencyKey=$key
$label=New-Object Windows.Forms.Label;$label.AutoSize=$true;$label.BackColor=$key;$label.ForeColor=[Drawing.Color]::White;$label.Font=New-Object Drawing.Font('Tahoma',12,[Drawing.FontStyle]::Bold);$form.Controls.Add($label)
$form.Add_Shown({$e=[OWin]::GetWindowLong($form.Handle,[OWin]::GWL_EXSTYLE);[OWin]::SetWindowLong($form.Handle,[OWin]::GWL_EXSTYLE,$e-bor[OWin]::WS_EX_TRANSPARENT-bor[OWin]::WS_EX_TOOLWINDOW-bor[OWin]::WS_EX_NOACTIVATE)|Out-Null;[OWin]::SetWindowDisplayAffinity($form.Handle,[OWin]::WDA_EXCLUDEFROMCAPTURE)|Out-Null})
$t=New-Object Windows.Forms.Timer;$t.Interval=100;$t.Add_Tick({try{$a=@(Get-Content $file -ErrorAction Stop|?{$_ -and $_.Trim()});$label.Text=$a -join "`r`n";$label.Visible=($a.Count-gt 0)}catch{$label.Visible=$false}});$t.Start();[Windows.Forms.Application]::Run($form)
