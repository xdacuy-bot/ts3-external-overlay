Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
$cs = @"
using System;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Windows.Forms;
using System.Runtime.InteropServices;
public static class OWin {
 [DllImport("user32.dll")] public static extern int GetWindowLong(IntPtr h,int n);
 [DllImport("user32.dll")] public static extern int SetWindowLong(IntPtr h,int n,int v);
 [DllImport("user32.dll")] public static extern bool SetWindowDisplayAffinity(IntPtr h,uint a);
 public const int GWL_EXSTYLE=-20, WS_EX_TRANSPARENT=0x20, WS_EX_TOOLWINDOW=0x80, WS_EX_NOACTIVATE=0x08000000;
 public const uint WDA_EXCLUDEFROMCAPTURE=0x11;
}
public class OutlineLabel : Control {
 public string Caption=""; public Color FillColor=Color.White; public float OutlineWidth=1.15f;
 public OutlineLabel(){SetStyle(ControlStyles.UserPaint|ControlStyles.AllPaintingInWmPaint|ControlStyles.OptimizedDoubleBuffer,true);}
 protected override void OnPaint(PaintEventArgs e){
  e.Graphics.SmoothingMode=SmoothingMode.AntiAlias;
  using(GraphicsPath p=new GraphicsPath()){
   float em=e.Graphics.DpiY*Font.SizeInPoints/72f;
   using(StringFormat sf=new StringFormat()){
    sf.Alignment=StringAlignment.Near; sf.LineAlignment=StringAlignment.Center;
    p.AddString(Caption,Font.FontFamily,(int)Font.Style,em,new RectangleF(2,0,Width-4,Height),sf);
   }
   using(Pen pen=new Pen(Color.FromArgb(220,15,15,15),OutlineWidth)){pen.LineJoin=LineJoin.Round;e.Graphics.DrawPath(pen,p);}
   using(SolidBrush b=new SolidBrush(FillColor)){e.Graphics.FillPath(b,p);}
  }
 }
}
"@
Add-Type -TypeDefinition $cs -ReferencedAssemblies @('System.Windows.Forms.dll','System.Drawing.dll')
$dir=Join-Path $env:APPDATA 'TS3ExternalOverlay';New-Item -ItemType Directory -Force $dir|Out-Null;$file=Join-Path $dir 'state.tsv'
$key=[Drawing.Color]::FromArgb(1,2,3);$w=245;$screen=[Windows.Forms.Screen]::PrimaryScreen.Bounds
$form=New-Object Windows.Forms.Form;$form.FormBorderStyle='None';$form.ShowInTaskbar=$false;$form.TopMost=$true;$form.StartPosition='Manual';$form.Location=New-Object Drawing.Point(($screen.Right-$w-8),8);$form.Size=New-Object Drawing.Size($w,360);$form.BackColor=$key;$form.TransparencyKey=$key
$panel=New-Object Windows.Forms.FlowLayoutPanel;$panel.FlowDirection='TopDown';$panel.WrapContents=$false;$panel.AutoSize=$true;$panel.BackColor=$key;$panel.Padding=New-Object Windows.Forms.Padding(0);$panel.Margin=New-Object Windows.Forms.Padding(0);$form.Controls.Add($panel)
$fUser=New-Object Drawing.Font('Tahoma',9,[Drawing.FontStyle]::Regular,[Drawing.GraphicsUnit]::Point);$fChan=New-Object Drawing.Font('Tahoma',9,[Drawing.FontStyle]::Bold,[Drawing.GraphicsUnit]::Point)
$normal=[Drawing.Color]::FromArgb(72,108,166);$talking=[Drawing.Color]::FromArgb(93,154,218);$muted=[Drawing.Color]::FromArgb(210,55,55);$channelColor=[Drawing.Color]::FromArgb(28,28,32)
function Row($text,$color,$channel){$p=New-Object Windows.Forms.Panel;$p.Width=241;$p.Height=18;$p.BackColor=$key;$p.Margin=New-Object Windows.Forms.Padding(0);$l=New-Object OutlineLabel;$l.Size=New-Object Drawing.Size(239,18);$l.Location=New-Object Drawing.Point(0,0);$l.Caption=$text;$l.Font=$(if($channel){$fChan}else{$fUser});$l.FillColor=$color;$l.OutlineWidth=$(if($channel){0.7}else{1.15});$l.BackColor=$key;$p.Controls.Add($l);return $p}
$form.Add_Shown({$e=[OWin]::GetWindowLong($form.Handle,[OWin]::GWL_EXSTYLE);[OWin]::SetWindowLong($form.Handle,[OWin]::GWL_EXSTYLE,$e-bor[OWin]::WS_EX_TRANSPARENT-bor[OWin]::WS_EX_TOOLWINDOW-bor[OWin]::WS_EX_NOACTIVATE)|Out-Null;[OWin]::SetWindowDisplayAffinity($form.Handle,[OWin]::WDA_EXCLUDEFROMCAPTURE)|Out-Null})
$t=New-Object Windows.Forms.Timer;$t.Interval=80;$t.Add_Tick({try{$lines=@(Get-Content $file -Encoding UTF8 -ErrorAction Stop);$sig=$lines-join[char]31;if($sig-ne$script:last){$script:last=$sig;$panel.SuspendLayout();$panel.Controls.Clear();foreach($line in $lines){$v=$line-split"`t",4;if($v[0]-eq'CHANNEL'){$panel.Controls.Add((Row $v[1] $channelColor $true))}elseif($v[0]-eq'USER'){$talk=$v[1]-eq'1';$mute=$v[2]-eq'1';$c=if($mute){$muted}elseif($talk){$talking}else{$normal};$panel.Controls.Add((Row $v[3] $c $false))}}$panel.ResumeLayout();$panel.Visible=$lines.Count-gt0}}catch{$panel.Visible=$false}});$t.Start();[Windows.Forms.Application]::Run($form)
