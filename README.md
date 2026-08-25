# twrp_device_google_emux64

x86_64 版本的 TWRP 模拟器设备树，对应 Google AVD `emux64`，产品名：

```text
twrp_emux64
```

构建后的运行目标是基于 `goldfish/ranchu` 的 x86_64 裸 QEMU 环境，
与 arm64 的 `twrp_emu64a` 设备树保持相同的结构和运行方式。

## 与 emu64a 的差异

| 项目        | emu64a                | emux64                                           |
| ----------- | --------------------- | ------------------------------------------------ |
| 架构        | arm64                 | x86_64                                           |
| QEMU 二进制 | qemu-system-aarch64   | qemu-system-x86_64                               |
| machine     | virt                  | pc (x86 Android emulator-compatible)             |
| 内核格式    | Image                 | bzImage                                          |
| 控制台/日志 | ttyAMA0               | `console=0`（QEMU 串口日志写入 `qemu_boot.log`） |
| 内核模块    | android-33 arm64 模块 | android-33 x86_64 模块（build 8949913）          |

## 内核与模块匹配

SDK 的 x86_64 `kernel-ranchu` 与 AOSP 预编译内核完全一致（MD5 相同）：

```text
5.15.41-android13-8-00055-g4f5025129fe8-ab8949913
```

对应 AOSP 模块仓库：

```text
https://android.googlesource.com/kernel/prebuilts/common-modules/virtual-device/5.15/x86-64
```

模块 checkout 到 commit `483eebf9499d`（"Update kernel to builds 8949913"），
所有 `.ko` 的 vermagic 与 SDK 内核逐字符一致。

## 编译流程

把本目录放到 TWRP / AOSP 源码树的 `device/google/emux64`：

```bash
source build/envsetup.sh
lunch twrp_emux64
m recoveryimage
```

产物：

```text
out/target/product/emux64/recovery.img
out/target/product/emux64/ramdisk-recovery.cpio
```

QEMU 启动链直接使用 `ramdisk-recovery.cpio`，放到本目录的 `artifacts/` 下。

## 启动方法（Windows）

```cmd
launch_qemu.cmd
```

默认使用 WHPX 硬件加速；如果主机的 WHPX 不可用，可强制使用 TCG：

```cmd
launch_qemu.cmd tcg
```

启动后 ADB 连接：

```cmd
adb connect 127.0.0.1:5557
```

## 前提

1. Windows + `qemu-system-x86_64`（默认 `D:\YuKongA\qemu\qemu-w64`）
2. Android SDK 的 android-33 x86_64 system image
   （默认 `D:\YuKongA\AndroidSDK\system-images\android-33\default\x86_64`）
3. 编译出来的 `ramdisk-recovery.cpio` 放在 `artifacts/` 下

## 目录结构

```text
AndroidProducts.mk
BoardConfig.mk
device.mk
twrp_emux64.mk
recovery.fstab
launch_qemu.cmd
fit_qemu_window.ps1
recovery/root/init.recovery.ranchu.rc
recovery/root/lib/modules/*.ko
recovery/root/system/etc/task_profiles.json
recovery/root/system/etc/twrp.flags
artifacts/            (ramdisk-recovery.cpio, qemu_userdata.img, qemu_boot.log)
```
