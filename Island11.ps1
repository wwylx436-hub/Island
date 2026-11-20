[CmdletBinding()]
param()

Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$createdNew = $false
$script:InstanceMutex = New-Object System.Threading.Mutex($true, 'Local\Island11Overlay', [ref]$createdNew)
if (-not $createdNew) {
    $script:InstanceMutex.Dispose()
    exit
}

Add-Type @"
using System;
using System.Runtime.InteropServices;

public static class Island11Power
{
    [StructLayout(LayoutKind.Sequential)]
    public struct SystemPowerStatus
    {
        public byte ACLineStatus;
        public byte BatteryFlag;
        public byte BatteryLifePercent;
        public byte Reserved1;
        public int BatteryLifeTime;
        public int BatteryFullLifeTime;
    }

    [DllImport("kernel32.dll")]
    public static extern bool GetSystemPowerStatus(out SystemPowerStatus status);
}
"@

[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Island 11"
        Width="248" Height="48"
        WindowStyle="None"
        AllowsTransparency="True"
        Background="Transparent"
        Topmost="True"
        ShowInTaskbar="False"
        ResizeMode="NoResize"
        SnapsToDevicePixels="True">
    <Window.Resources>
        <Style x:Key="IslandButton" TargetType="Button">
            <Setter Property="Foreground" Value="#F4F4F5"/>
            <Setter Property="Background" Value="#18FFFFFF"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="FontFamily" Value="Segoe UI"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border Background="{TemplateBinding Background}" CornerRadius="10" Padding="10,6">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
    </Window.Resources>

    <Border x:Name="IslandShell"
            CornerRadius="24"
            Background="#F20A0A0D"
            BorderBrush="#24FFFFFF"
            BorderThickness="1"
            ClipToBounds="True"
            Cursor="Hand">
        <Border.Effect>
            <DropShadowEffect BlurRadius="24" ShadowDepth="4" Opacity="0.48" Color="#000000"/>
        </Border.Effect>

        <Grid>
            <Grid x:Name="CompactView" Margin="8,0">
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="36"/>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="54"/>
                </Grid.ColumnDefinitions>

                <Grid Width="24" Height="24" HorizontalAlignment="Center" VerticalAlignment="Center">
                    <Ellipse Fill="#1822C55E" Stroke="#3A22C55E" StrokeThickness="1"/>
                    <Ellipse x:Name="StatusDot" Width="8" Height="8" Fill="#34D058"/>
                </Grid>

                <StackPanel Grid.Column="1" VerticalAlignment="Center">
                    <TextBlock Text="ISLAND 11" Foreground="#F4F4F5" FontSize="11" FontWeight="SemiBold" FontFamily="Segoe UI"/>
                    <TextBlock x:Name="CompactStatus" Text="Ready" Foreground="#8D8D96" FontSize="9" FontFamily="Segoe UI" Margin="0,-1,0,0"/>
                </StackPanel>

                <TextBlock x:Name="CompactClock" Grid.Column="2" Text="00:00" Foreground="#FAFAFA" FontSize="13" FontWeight="SemiBold" FontFamily="Segoe UI" HorizontalAlignment="Center" VerticalAlignment="Center"/>
            </Grid>

            <Grid x:Name="ExpandedView" Visibility="Hidden" Opacity="0" Margin="18,13,18,16">
                <Grid.RowDefinitions>
                    <RowDefinition Height="30"/>
                    <RowDefinition Height="1"/>
                    <RowDefinition Height="*"/>
                </Grid.RowDefinitions>

                <Grid>
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="Auto"/>
                    </Grid.ColumnDefinitions>
                    <StackPanel Orientation="Horizontal" VerticalAlignment="Center">
                        <Ellipse Width="8" Height="8" Fill="#34D058" Margin="0,0,9,0"/>
                        <TextBlock Text="ISLAND 11" Foreground="#F4F4F5" FontSize="12" FontWeight="SemiBold" FontFamily="Segoe UI" VerticalAlignment="Center"/>
                    </StackPanel>
                    <StackPanel Grid.Column="1" Orientation="Horizontal">
                        <TextBlock x:Name="ExpandedClock" Text="00:00" Foreground="#B9B9C0" FontSize="12" FontFamily="Segoe UI" VerticalAlignment="Center" Margin="0,0,10,0"/>
                        <Button x:Name="HideButton" Content="&#x2715;" Width="28" Height="24" Padding="0" ToolTip="Hide to tray" Style="{StaticResource IslandButton}"/>
                    </StackPanel>
                </Grid>

                <Border Grid.Row="1" Background="#16FFFFFF"/>

                <Grid Grid.Row="2" Margin="0,13,0,0">
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="52"/>
                        <ColumnDefinition Width="*"/>
                    </Grid.ColumnDefinitions>

                    <Border Width="42" Height="42" CornerRadius="14" Background="#1E7C3AED" HorizontalAlignment="Left" VerticalAlignment="Top">
                        <TextBlock Text="&#x25CF;" Foreground="#A78BFA" FontSize="19" HorizontalAlignment="Center" VerticalAlignment="Center"/>
                    </Border>

                    <StackPanel Grid.Column="1" VerticalAlignment="Top">
                        <TextBlock x:Name="PrimaryText" Text="Everything is ready" Foreground="#FAFAFA" FontSize="14" FontWeight="SemiBold" FontFamily="Segoe UI"/>
                        <TextBlock x:Name="SecondaryText" Text="Your desktop island is running" Foreground="#8D8D96" FontSize="10" FontFamily="Segoe UI" Margin="0,2,0,8"/>
                        <Grid>
                            <ProgressBar x:Name="BatteryBar" Height="4" Minimum="0" Maximum="100" Value="72" Background="#25252B" Foreground="#8B5CF6" BorderThickness="0"/>
                            <TextBlock x:Name="BatteryText" Text="Power" Foreground="#73737C" FontSize="9" HorizontalAlignment="Right" Margin="0,7,0,0"/>
                        </Grid>
                    </StackPanel>
                </Grid>
            </Grid>
        </Grid>
    </Border>
</Window>
"@

$reader = New-Object System.Xml.XmlNodeReader $xaml
$window = [Windows.Markup.XamlReader]::Load($reader)

$islandShell = $window.FindName('IslandShell')
$compactView = $window.FindName('CompactView')
$expandedView = $window.FindName('ExpandedView')
$compactClock = $window.FindName('CompactClock')
$expandedClock = $window.FindName('ExpandedClock')
$compactStatus = $window.FindName('CompactStatus')
$primaryText = $window.FindName('PrimaryText')
$secondaryText = $window.FindName('SecondaryText')
$batteryBar = $window.FindName('BatteryBar')
$batteryText = $window.FindName('BatteryText')
$statusDot = $window.FindName('StatusDot')
$hideButton = $window.FindName('HideButton')

$script:IsExpanded = $false
$script:IsExiting = $false
$script:LastMinute = ''

function Get-WorkArea {
    return [System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea
}

function Set-IslandPosition {
    $workArea = Get-WorkArea
    $window.Left = $workArea.Left + (($workArea.Width - $window.Width) / 2)
    $window.Top = $workArea.Top + 8
}

function Start-NumberAnimation {
    param(
        [System.Windows.DependencyObject]$Target,
        [System.Windows.DependencyProperty]$Property,
        [double]$To,
        [int]$Milliseconds = 260
    )

    $animation = New-Object System.Windows.Media.Animation.DoubleAnimation
    $animation.To = $To
    $animation.Duration = [System.Windows.Duration]::new([TimeSpan]::FromMilliseconds($Milliseconds))
    $animation.EasingFunction = New-Object System.Windows.Media.Animation.QuinticEase
    $animation.EasingFunction.EasingMode = [System.Windows.Media.Animation.EasingMode]::EaseOut
    $animation.FillBehavior = [System.Windows.Media.Animation.FillBehavior]::HoldEnd
    $Target.BeginAnimation($Property, $animation)
}

function Start-FadeAnimation {
    param(
        [System.Windows.UIElement]$Target,
        [double]$To,
        [int]$Milliseconds = 160
    )

    $animation = New-Object System.Windows.Media.Animation.DoubleAnimation
    $animation.To = $To
    $animation.Duration = [System.Windows.Duration]::new([TimeSpan]::FromMilliseconds($Milliseconds))
    $animation.EasingFunction = New-Object System.Windows.Media.Animation.QuadraticEase
    $animation.EasingFunction.EasingMode = [System.Windows.Media.Animation.EasingMode]::EaseOut
    $Target.BeginAnimation([System.Windows.UIElement]::OpacityProperty, $animation)
}

function Expand-Island {
    if ($script:IsExpanded) { return }
    $script:IsExpanded = $true
    $compactView.Visibility = [System.Windows.Visibility]::Hidden
    $expandedView.Visibility = [System.Windows.Visibility]::Visible
    $expandedView.Opacity = 0
    $islandShell.CornerRadius = [System.Windows.CornerRadius]::new(26)
    Start-NumberAnimation -Target $window -Property ([System.Windows.Window]::WidthProperty) -To 372
    Start-NumberAnimation -Target $window -Property ([System.Windows.Window]::HeightProperty) -To 150
    Start-FadeAnimation -Target $expandedView -To 1 -Milliseconds 230
}

function Collapse-Island {
    if (-not $script:IsExpanded) { return }
    $script:IsExpanded = $false
    $expandedView.Visibility = [System.Windows.Visibility]::Hidden
    $compactView.Visibility = [System.Windows.Visibility]::Visible
    $compactView.Opacity = 0
    $islandShell.CornerRadius = [System.Windows.CornerRadius]::new(24)
    Start-NumberAnimation -Target $window -Property ([System.Windows.Window]::WidthProperty) -To 248
    Start-NumberAnimation -Target $window -Property ([System.Windows.Window]::HeightProperty) -To 48
    Start-FadeAnimation -Target $compactView -To 1 -Milliseconds 230
}

function Toggle-Island {
    if ($script:IsExpanded) { Collapse-Island } else { Expand-Island }
}

function Update-IslandStatus {
    $now = Get-Date
    $time = $now.ToString('HH:mm')
    $compactClock.Text = $time
    $expandedClock.Text = $time

    $powerStatus = New-Object Island11Power+SystemPowerStatus
    if ([Island11Power]::GetSystemPowerStatus([ref]$powerStatus)) {
        if ($powerStatus.BatteryLifePercent -ne 255) {
            $percent = [int]$powerStatus.BatteryLifePercent
            $batteryBar.Value = $percent
            $source = if ($powerStatus.ACLineStatus -eq 1) { 'Charging' } else { 'Battery' }
            $batteryText.Text = "$source - $percent%"
            $compactStatus.Text = "$source $percent%"
            if ($percent -le 20 -and $powerStatus.ACLineStatus -ne 1) {
                $batteryBar.Foreground = [System.Windows.Media.Brushes]::Tomato
                $statusDot.Fill = [System.Windows.Media.Brushes]::Tomato
            } else {
                $batteryBar.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString('#8B5CF6')
                $statusDot.Fill = [System.Windows.Media.BrushConverter]::new().ConvertFromString('#34D058')
            }
        } else {
            $batteryBar.Value = 100
            $batteryText.Text = 'Desktop power'
            $compactStatus.Text = 'Ready'
        }
    }
}

$trayIcon = New-Object System.Windows.Forms.NotifyIcon
$trayIcon.Text = 'Island 11'
$trayIcon.Icon = [System.Drawing.SystemIcons]::Application
$trayIcon.Visible = $true

$trayMenu = New-Object System.Windows.Forms.ContextMenuStrip
$openItem = $trayMenu.Items.Add('Open Island')
$collapseItem = $trayMenu.Items.Add('Compact mode')
$trayMenu.Items.Add('-') | Out-Null
$exitItem = $trayMenu.Items.Add('Exit')
$trayIcon.ContextMenuStrip = $trayMenu

$openItem.Add_Click({
    $window.Show()
    Expand-Island
    $window.Activate()
})

$collapseItem.Add_Click({
    $window.Show()
    Collapse-Island
})

$exitItem.Add_Click({
    $script:IsExiting = $true
    $trayIcon.Visible = $false
    $trayIcon.Dispose()
    $window.Close()
})

$trayIcon.Add_DoubleClick({
    $window.Show()
    Toggle-Island
})

$islandShell.Add_MouseLeftButtonUp({
    param($sender, $eventArgs)

    $source = $eventArgs.OriginalSource
    while ($null -ne $source -and -not ($source -is [System.Windows.Controls.Button])) {
        $source = [System.Windows.Media.VisualTreeHelper]::GetParent($source)
    }
    if ($source -is [System.Windows.Controls.Button]) { return }

    Toggle-Island
    $eventArgs.Handled = $true
})

$hideButton.Add_Click({
    param($sender, $eventArgs)
    $window.Hide()
    $eventArgs.Handled = $true
})

$window.Add_SizeChanged({ Set-IslandPosition })
$window.Add_LocationChanged({
    # Keep the island anchored when Windows changes the work area.
    if (-not $window.IsMouseCaptureWithin) { Set-IslandPosition }
})

$window.Add_KeyDown({
    param($sender, $eventArgs)
    if ($eventArgs.Key -eq [System.Windows.Input.Key]::Escape) {
        if ($script:IsExpanded) { Collapse-Island } else { $window.Hide() }
        $eventArgs.Handled = $true
    }
})

$window.Add_Closing({
    param($sender, $eventArgs)
    if (-not $script:IsExiting) {
        $eventArgs.Cancel = $true
        $window.Hide()
    }
})

$window.Add_Closed({
    $trayIcon.Visible = $false
    $trayIcon.Dispose()
})

$timer = New-Object System.Windows.Threading.DispatcherTimer
$timer.Interval = [TimeSpan]::FromSeconds(1)
$timer.Add_Tick({ Update-IslandStatus })

$window.Add_Loaded({
    Set-IslandPosition
    Update-IslandStatus
    $timer.Start()
})

$app = New-Object System.Windows.Application
$app.ShutdownMode = [System.Windows.ShutdownMode]::OnLastWindowClose
try {
    $null = $app.Run($window)
} finally {
    $script:InstanceMutex.ReleaseMutex()
    $script:InstanceMutex.Dispose()
}

