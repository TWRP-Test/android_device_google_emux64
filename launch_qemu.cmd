@echo off
setlocal EnableExtensions

rem Windows launcher for the TWRP emux64 recovery image.
set "SCRIPT_DIR=%~dp0"
set "QEMU_DIR=%SCRIPT_DIR%qemu-w64"
if not exist "%QEMU_DIR%\qemu-system-x86_64.exe" set "QEMU_DIR=D:\YuKongA\qemu\qemu-w64"
set "QEMU=%QEMU_DIR%\qemu-system-x86_64.exe"
set "QEMU_IMG=%QEMU_DIR%\qemu-img.exe"
set "SDK_X64=D:\YuKongA\AndroidSDK\system-images\android-33\default\x86_64"
set "KERNEL=%SDK_X64%\kernel-ranchu"
set "RAMDISK=%SCRIPT_DIR%artifacts\ramdisk-recovery.cpio"
if not exist "%RAMDISK%" set "RAMDISK=D:\GitHub\android_device_google_emux64\artifacts\ramdisk-recovery.cpio"
set "ARTIFACTS=%SCRIPT_DIR%artifacts"
set "LOG=%ARTIFACTS%\qemu_boot.log"
set "DATA_IMG=%ARTIFACTS%\qemu_userdata.img"
set "ADB=D:\YuKongA\AndroidSDK\platform-tools\adb.exe"
set "WIDTH=1080"
set "HEIGHT=1920"
set "REFRESH=60"

rem WHPX is the fast path on Windows. Use a conservative CPU model because
rem QEMU 11 can crash when WHPX is combined with -cpu max. Pass "tcg" to
rem force the software fallback.
set "ACCEL=whpx"
set "CPU=qemu64"
if /i "%~1"=="tcg" (
    set "ACCEL=tcg"
    set "CPU=max"
)

if not exist "%QEMU%" goto missing
if not exist "%QEMU_IMG%" goto missing
if not exist "%KERNEL%" goto missing
if not exist "%RAMDISK%" goto missing
if not exist "%ARTIFACTS%" mkdir "%ARTIFACTS%"
if not exist "%DATA_IMG%" (
    echo Creating 512M userdata image...
    "%QEMU_IMG%" create -f raw "%DATA_IMG%" 512M
    if errorlevel 1 exit /b 1
)

echo Starting TWRP emux64...
echo Accel: %ACCEL%
echo CPU: %CPU%
echo QEMU log: %LOG%
echo ADB command after boot: "%ADB%" connect 127.0.0.1:5557

if exist "%~dp0fit_qemu_window.ps1" (
    start "" /b powershell.exe -NoLogo -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File "%~dp0fit_qemu_window.ps1" -GuestWidth %WIDTH% -GuestHeight %HEIGHT%
)

"%QEMU%" ^
    -machine pc,accel=%ACCEL% ^
    -cpu %CPU% ^
    -smp 4 ^
    -m 4096 ^
    -kernel "%KERNEL%" ^
    -initrd "%RAMDISK%" ^
    -drive file="%DATA_IMG%",if=none,format=raw,id=userdata ^
    -nodefaults ^
    -append "8250.nr_uarts=1 clocksource=pit no_timer_check console=0 androidboot.hardware=ranchu androidboot.selinux=permissive androidboot.serialno=QEMU0001 qemu=1 skip_initramfs video=Virtual-1:%WIDTH%x%HEIGHT%@%REFRESH%" ^
    -device virtio-gpu-pci,edid=on,xres=%WIDTH%,yres=%HEIGHT% ^
    -device virtio-rng-pci ^
    -device virtio-serial-pci,ioeventfd=off ^
    -device usb-ehci ^
    -device usb-storage,drive=userdata ^
    -device usb-mouse ^
    -device virtio-net-pci,netdev=net0 ^
    -netdev user,id=net0,hostfwd=tcp::5557-:5555 ^
    -vga none ^
    -display gtk,full-screen=off,show-menubar=off,show-cursor=off,zoom-to-fit=on ^
    -serial file:"%LOG%" ^
    -monitor tcp:127.0.0.1:5558,server,nowait ^
    -no-reboot

set "EXIT_CODE=%ERRORLEVEL%"
if not "%EXIT_CODE%"=="0" (
    echo QEMU exited with code %EXIT_CODE%.
    pause
)
exit /b %EXIT_CODE%

:missing
echo Missing required file.
echo QEMU:    %QEMU%
echo QEMU img: %QEMU_IMG%
echo Kernel:  %KERNEL%
echo Ramdisk: %RAMDISK%
pause
exit /b 1
