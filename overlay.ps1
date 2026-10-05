Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
$cs = @"
using System;
using System.Drawing;
using System.Windows.Forms;
using System.Runtime.InteropServices;
public static class OWin {
 [DllImport("user32.dll")] public static extern int GetWindowLong(IntPtr h,int n);
 [DllImport("user32.dll")] public static extern int SetWindowLong(IntPtr h,int n,int v);
 [DllImport("user32.dll")] public static extern bool SetWindowDisplayAffinity(IntPtr h,uint a);
 public const int GWL_EXSTYLE=-20, WS_EX_TRANSPARENT=0x20, WS_EX_TOOLWINDOW=0x80, WS_EX_NOACTIVATE=0x08000000;
 public const uint WDA_EXCLUDEFROMCAPTURE=0x11;
}
public class TSNLabel : Control {
 public string Caption="";
 public Color TextColor=Color.White;
 public TSNLabel(){ SetStyle(ControlStyles.UserPaint|ControlStyles.AllPaintingInWmPaint|ControlStyles.OptimizedDoubleBuffer|ControlStyles.SupportsTransparentBackColor,true); BackColor=Color.Transparent; }
 protected override void OnPaint(PaintEventArgs e){
   e.Graphics.TextRenderingHint=System.Drawing.Text.TextRenderingHint.ClearTypeGridFit;
   TextRenderer.DrawText(e.Graphics,Caption,Font,new Point(0,-1),TextColor,Color.Transparent,TextFormatFlags.NoPadding|TextFormatFlags.NoPrefix|TextFormatFlags.SingleLine);
 }
}
"@
Add-Type -TypeDefinition $cs -ReferencedAssemblies System.Windows.Forms,System.Drawing
$dir=Join-Path $env:APPDATA 'TS3ExternalOverlay';New-Item -ItemType Directory -Force $dir|Out-Null;$file=Join-Path $dir 'state.tsv'
$key=[Drawing.Color]::FromArgb(1,2,3);$w=205;$screen=[Windows.Forms.Screen]::PrimaryScreen.Bounds
$form=New-Object Windows.Forms.Form;$form.FormBorderStyle='None';$form.ShowInTaskbar=$false;$form.TopMost=$true;$form.StartPosition='Manual';$form.Location=New-Object Drawing.Point(($screen.Right-$w-8),8);$form.Size=New-Object Drawing.Size($w,300);$form.BackColor=$key;$form.TransparencyKey=$key
$panel=New-Object Windows.Forms.FlowLayoutPanel;$panel.FlowDirection='TopDown';$panel.WrapContents=$false;$panel.AutoSize=$true;$panel.BackColor=$key;$panel.Padding=New-Object Windows.Forms.Padding(0);$panel.Margin=New-Object Windows.Forms.Padding(0);$form.Controls.Add($panel)
# Calibrated from the side-by-side TSNotifier reference: the previous 15px face was
# visibly ~25-30% too tall/wide. 12px Tahoma reproduces the compact original scale.
$fUser=New-Object Drawing.Font('Tahoma',12,[Drawing.FontStyle]::Regular,[Drawing.GraphicsUnit]::Pixel)
$fChan=New-Object Drawing.Font('Tahoma',12,[Drawing.FontStyle]::Bold,[Drawing.GraphicsUnit]::Pixel)
# Keep the TSNotifier-like state palette. Idle stays blue; speaking is a restrained
# cyan; muted is a soft red. Channel text uses dark charcoal rather than pure black.
$idle=[Drawing.Color]::FromArgb(52,91,151)
$talking=[Drawing.Color]::FromArgb(91,164,198)
$muted=[Drawing.Color]::FromArgb(190,91,91)
$channelColor=[Drawing.Color]::FromArgb(38,38,42)
function Row($text,$color,$channel){
 $p=New-Object Windows.Forms.Panel;$p.Width=201;$p.Height=14;$p.BackColor=$key;$p.Margin=New-Object Windows.Forms.Padding(0)
 $l=New-Object TSNLabel;$l.Size=New-Object Drawing.Size(199,14);$l.Location=New-Object Drawing.Point(0,0);$l.Caption=$text;$l.Font=$(if($channel){$fChan}else{$fUser});$l.TextColor=$color;$l.Margin=New-Object Windows.Forms.Padding(0);$p.Controls.Add($l);return $p
}
$form.Add_Shown({$e=[OWin]::GetWindowLong($form.Handle,[OWin]::GWL_EXSTYLE);[OWin]::SetWindowLong($form.Handle,[OWin]::GWL_EXSTYLE,$e-bor[OWin]::WS_EX_TRANSPARENT-bor[OWin]::WS_EX_TOOLWINDOW-bor[OWin]::WS_EX_NOACTIVATE)|Out-Null;[OWin]::SetWindowDisplayAffinity($form.Handle,[OWin]::WDA_EXCLUDEFROMCAPTURE)|Out-Null})
$t=New-Object Windows.Forms.Timer;$t.Interval=80;$t.Add_Tick({try{$lines=@(Get-Content $file -Encoding UTF8 -ErrorAction Stop);$sig=$lines-join[char]31;if($sig-ne$script:last){$script:last=$sig;$panel.SuspendLayout();$panel.Controls.Clear();foreach($line in $lines){$v=$line-split"`t",4;if($v[0]-eq'CHANNEL'){$panel.Controls.Add((Row $v[1] $channelColor $true))}elseif($v[0]-eq'USER'){$talk=$v[1]-eq'1';$mute=$v[2]-eq'1';$c=if($mute){$muted}elseif($talk){$talking}else{$idle};$panel.Controls.Add((Row $v[3] $c $false))}}$panel.ResumeLayout();$panel.Visible=$lines.Count-gt0}}catch{$panel.Visible=$false}});$t.Start();[Windows.Forms.Application]::Run($form)
