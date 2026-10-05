Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type @"
using System; using System.Runtime.InteropServices;
public static class OWin {[DllImport("user32.dll")]public static extern int GetWindowLong(IntPtr h,int n);[DllImport("user32.dll")]public static extern int SetWindowLong(IntPtr h,int n,int v);[DllImport("user32.dll")]public static extern bool SetWindowDisplayAffinity(IntPtr h,uint a);public const int GWL_EXSTYLE=-20,WS_EX_TRANSPARENT=0x20,WS_EX_TOOLWINDOW=0x80,WS_EX_NOACTIVATE=0x08000000;public const uint WDA_EXCLUDEFROMCAPTURE=0x11;}
"@
$dir=Join-Path $env:APPDATA 'TS3ExternalOverlay';New-Item -ItemType Directory -Force $dir|Out-Null;$file=Join-Path $dir 'state.tsv'
$key=[Drawing.Color]::FromArgb(1,2,3)
# Compact TSNotifier-style block in the extreme top-right.
$w=250;$marginX=7;$marginY=7;$screen=[Windows.Forms.Screen]::PrimaryScreen.Bounds
$form=New-Object Windows.Forms.Form;$form.FormBorderStyle='None';$form.ShowInTaskbar=$false;$form.TopMost=$true;$form.StartPosition='Manual';$form.Location=New-Object Drawing.Point(($screen.Right-$w-$marginX),$marginY);$form.Size=New-Object Drawing.Size($w,320);$form.BackColor=$key;$form.TransparencyKey=$key
$panel=New-Object Windows.Forms.FlowLayoutPanel;$panel.FlowDirection='TopDown';$panel.WrapContents=$false;$panel.AutoSize=$true;$panel.BackColor=$key;$panel.Padding=New-Object Windows.Forms.Padding(0);$panel.Margin=New-Object Windows.Forms.Padding(0);$form.Controls.Add($panel)
# Small font and tight spacing, close to the original TSNotifier screenshot.
$fUser=New-Object Drawing.Font('Tahoma',8.25,[Drawing.FontStyle]::Regular,[Drawing.GraphicsUnit]::Point)
$fChan=New-Object Drawing.Font('Tahoma',8.25,[Drawing.FontStyle]::Bold,[Drawing.GraphicsUnit]::Point)
$normal=[Drawing.Color]::FromArgb(82,119,171)
$talking=[Drawing.Color]::FromArgb(112,181,238)
$muted=[Drawing.Color]::FromArgb(220,70,70)
$channelColor=[Drawing.Color]::FromArgb(225,225,225)
function Row($text,$color,$channel){
 $p=New-Object Windows.Forms.Panel;$p.Width=246;$p.Height=16;$p.BackColor=$key;$p.Margin=New-Object Windows.Forms.Padding(0);$p.Padding=New-Object Windows.Forms.Padding(0)
 $l=New-Object Windows.Forms.Label;$l.AutoSize=$false;$l.Size=New-Object Drawing.Size(244,16);$l.Location=New-Object Drawing.Point(0,0);$l.TextAlign='MiddleRight';$l.Text=$text;$l.Font=$(if($channel){$fChan}else{$fUser});$l.ForeColor=$color;$l.BackColor=$key;$l.Margin=New-Object Windows.Forms.Padding(0);$l.Padding=New-Object Windows.Forms.Padding(0);$p.Controls.Add($l);return $p
}
$form.Add_Shown({$e=[OWin]::GetWindowLong($form.Handle,[OWin]::GWL_EXSTYLE);[OWin]::SetWindowLong($form.Handle,[OWin]::GWL_EXSTYLE,$e-bor[OWin]::WS_EX_TRANSPARENT-bor[OWin]::WS_EX_TOOLWINDOW-bor[OWin]::WS_EX_NOACTIVATE)|Out-Null;[OWin]::SetWindowDisplayAffinity($form.Handle,[OWin]::WDA_EXCLUDEFROMCAPTURE)|Out-Null})
$t=New-Object Windows.Forms.Timer;$t.Interval=80;$t.Add_Tick({try{$lines=@(Get-Content $file -Encoding UTF8 -ErrorAction Stop);$sig=$lines-join[char]31;if($sig-ne$script:last){$script:last=$sig;$panel.SuspendLayout();$panel.Controls.Clear();foreach($line in $lines){$v=$line-split"`t",4;if($v[0]-eq'CHANNEL'){$panel.Controls.Add((Row $v[1] $channelColor $true))}elseif($v[0]-eq'USER'){$talk=$v[1]-eq'1';$mute=$v[2]-eq'1';$c=if($mute){$muted}elseif($talk){$talking}else{$normal};$panel.Controls.Add((Row $v[3] $c $false))}}$panel.ResumeLayout();$panel.Visible=$lines.Count-gt0}}catch{$panel.Visible=$false}});$t.Start();[Windows.Forms.Application]::Run($form)
