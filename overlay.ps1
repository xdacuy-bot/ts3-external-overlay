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

# TSNotifier-like compact speaker list. Edit these values later if desired.
$x=18; $y=205; $fontSize=10.5
$form=New-Object Windows.Forms.Form
$form.FormBorderStyle='None'; $form.ShowInTaskbar=$false; $form.TopMost=$true
$form.StartPosition='Manual'; $form.Location=New-Object Drawing.Point($x,$y); $form.Size=New-Object Drawing.Size(460,350)
$key=[Drawing.Color]::FromArgb(1,2,3); $form.BackColor=$key; $form.TransparencyKey=$key

$panel=New-Object Windows.Forms.FlowLayoutPanel
$panel.FlowDirection='TopDown'; $panel.WrapContents=$false; $panel.AutoSize=$true; $panel.BackColor=$key
$panel.Padding=New-Object Windows.Forms.Padding(0); $panel.Margin=New-Object Windows.Forms.Padding(0)
$form.Controls.Add($panel)

$font=New-Object Drawing.Font('Segoe UI Semibold',$fontSize,[Drawing.FontStyle]::Regular,[Drawing.GraphicsUnit]::Point)
$rows=@{}
function New-TalkerRow([string]$name){
 $row=New-Object Windows.Forms.Panel; $row.Width=440; $row.Height=24; $row.BackColor=$key; $row.Margin=New-Object Windows.Forms.Padding(0,0,0,1)
 $dot=New-Object Windows.Forms.Label; $dot.Text=[char]0x25CF; $dot.AutoSize=$false; $dot.Size=New-Object Drawing.Size(18,22); $dot.Location=New-Object Drawing.Point(0,1); $dot.TextAlign='MiddleCenter'; $dot.Font=New-Object Drawing.Font('Segoe UI Symbol',10); $dot.ForeColor=[Drawing.Color]::FromArgb(82,196,26); $dot.BackColor=$key
 $txt=New-Object Windows.Forms.Label; $txt.Text=$name; $txt.AutoSize=$true; $txt.Location=New-Object Drawing.Point(20,2); $txt.Font=$font; $txt.ForeColor=[Drawing.Color]::FromArgb(238,238,238); $txt.BackColor=$key
 $row.Controls.Add($dot); $row.Controls.Add($txt); return $row
}

$form.Add_Shown({
 $e=[OWin]::GetWindowLong($form.Handle,[OWin]::GWL_EXSTYLE)
 [OWin]::SetWindowLong($form.Handle,[OWin]::GWL_EXSTYLE,$e-bor[OWin]::WS_EX_TRANSPARENT-bor[OWin]::WS_EX_TOOLWINDOW-bor[OWin]::WS_EX_NOACTIVATE)|Out-Null
 [OWin]::SetWindowDisplayAffinity($form.Handle,[OWin]::WDA_EXCLUDEFROMCAPTURE)|Out-Null
})

$t=New-Object Windows.Forms.Timer; $t.Interval=80
$t.Add_Tick({
 try{
  $a=@(Get-Content $file -ErrorAction Stop | ?{$_ -and $_.Trim()} | %{ $_.Trim() })
  $sig=($a -join [char]31)
  if($script:lastSig -ne $sig){
   $script:lastSig=$sig; $panel.SuspendLayout(); $panel.Controls.Clear()
   foreach($name in $a){$panel.Controls.Add((New-TalkerRow $name))}
   $panel.ResumeLayout(); $panel.Visible=($a.Count -gt 0)
  }
 }catch{$panel.Visible=$false}
})
$t.Start(); [Windows.Forms.Application]::Run($form)
