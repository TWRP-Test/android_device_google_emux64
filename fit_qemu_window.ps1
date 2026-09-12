param(
    [Parameter(Mandatory = $true)]
    [int]$GuestWidth,
    [Parameter(Mandatory = $true)]
    [int]$GuestHeight
)

Add-Type -AssemblyName System.Windows.Forms

Add-Type @'
using System;
using System.Runtime.InteropServices;

public static class QemuWindowNative {
    [StructLayout(LayoutKind.Sequential)]
    public struct RECT {
        public int Left;
        public int Top;
        public int Right;
        public int Bottom;
    }

    [DllImport("user32.dll", SetLastError = true)]
    public static extern bool GetWindowRect(IntPtr hWnd, out RECT rect);

    [DllImport("user32.dll")]
    public static extern bool GetClientRect(IntPtr hWnd, out RECT rect);

    [DllImport("user32.dll", SetLastError = true)]
    public static extern bool SetWindowPos(
        IntPtr hWnd,
        IntPtr hWndInsertAfter,
        int x,
        int y,
        int cx,
        int cy,
        uint flags);
}
'@

$swpNoZOrder = 0x0004
$swpNoActivate = 0x0010
$deadline = [DateTime]::UtcNow.AddSeconds(45)
$stableCount = 0

while ([DateTime]::UtcNow -lt $deadline) {
    $qemuProcess = Get-Process -Name qemu-system-x86_64 -ErrorAction SilentlyContinue |
        Sort-Object StartTime -Descending |
        Select-Object -First 1

    if ($null -eq $qemuProcess -or $qemuProcess.MainWindowHandle -eq 0) {
        Start-Sleep -Milliseconds 250
        continue
    }

    $windowRect = New-Object QemuWindowNative+RECT
    $clientRect = New-Object QemuWindowNative+RECT
    [QemuWindowNative]::GetWindowRect($qemuProcess.MainWindowHandle, [ref]$windowRect) | Out-Null
    [QemuWindowNative]::GetClientRect($qemuProcess.MainWindowHandle, [ref]$clientRect) | Out-Null

    $outerWidth = $windowRect.Right - $windowRect.Left
    $outerHeight = $windowRect.Bottom - $windowRect.Top
    $clientWidth = $clientRect.Right - $clientRect.Left
    $clientHeight = $clientRect.Bottom - $clientRect.Top
    $frameWidth = [Math]::Max(0, $outerWidth - $clientWidth)
    $frameHeight = [Math]::Max(0, $outerHeight - $clientHeight)

    $screen = [System.Windows.Forms.Screen]::FromHandle($qemuProcess.MainWindowHandle)
    if ($null -eq $screen) {
        $screen = [System.Windows.Forms.Screen]::PrimaryScreen
    }

    $margin = 8
    $availableWidth = [Math]::Max(1, $screen.WorkingArea.Width - $frameWidth - (2 * $margin))
    $availableHeight = [Math]::Max(1, $screen.WorkingArea.Height - $frameHeight - (2 * $margin))
    $scale = [Math]::Min(
        ($availableWidth / [double]$GuestWidth),
        ($availableHeight / [double]$GuestHeight))

    $targetClientWidth = [Math]::Max(1, [int][Math]::Floor($GuestWidth * $scale))
    $targetClientHeight = [Math]::Max(1, [int][Math]::Floor($GuestHeight * $scale))
    $targetOuterWidth = $targetClientWidth + $frameWidth
    $targetOuterHeight = $targetClientHeight + $frameHeight
    $targetLeft = $screen.WorkingArea.Left + [int][Math]::Floor(($screen.WorkingArea.Width - $targetOuterWidth) / 2)
    $targetTop = $screen.WorkingArea.Top + [int][Math]::Floor(($screen.WorkingArea.Height - $targetOuterHeight) / 2)

    if ($outerWidth -eq $targetOuterWidth -and $outerHeight -eq $targetOuterHeight) {
        $stableCount++
        if ($stableCount -ge 6) {
            break
        }
    } else {
        $stableCount = 0
        [QemuWindowNative]::SetWindowPos(
            $qemuProcess.MainWindowHandle,
            [IntPtr]::Zero,
            $targetLeft,
            $targetTop,
            $targetOuterWidth,
            $targetOuterHeight,
            $swpNoZOrder -bor $swpNoActivate) | Out-Null
    }

    Start-Sleep -Milliseconds 500
}
