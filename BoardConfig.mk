#
# Copyright (C) 2026 The Android Open Source Project
#
# SPDX-License-Identifier: Apache-2.0
#

# Building with minimal manifest
ALLOW_MISSING_DEPENDENCIES                      := true
BUILD_BROKEN_DUP_RULES                          := true
BUILD_BROKEN_ELF_PREBUILT_PRODUCT_COPY_FILES    := true

# Architecture
TARGET_ARCH                 := x86_64
TARGET_ARCH_VARIANT         := x86_64
TARGET_CPU_ABI              := x86_64
TARGET_CPU_VARIANT          := generic

# A/B
AB_OTA_PARTITIONS := \
    boot \
    dtbo \
    product \
    system \
    system_ext \
    vbmeta \
    vbmeta_system \
    vendor \
    vendor_dlkm

# Platform / Bootloader
# Goldfish is the AOSP virtual hardware platform used by AVD
PRODUCT_PLATFORM                := goldfish
TARGET_BOOTLOADER_BOARD_NAME    := goldfish

# Crypto
# BOARD_USES_METADATA_PARTITION disabled — QEMU has no metadata partition
# Crypto — emulator does not use hardware-backed TEE,
# so we disable OMAPI and use software fallback paths.
TW_INCLUDE_CRYPTO               := false

# Debug
TARGET_USES_LOGD                := true
TWRP_INCLUDE_LOGCAT             := true
TARGET_RECOVERY_DEVICE_MODULES  += debuggerd
TARGET_RECOVERY_DEVICE_MODULES  += strace
RECOVERY_BINARY_SOURCE_FILES    += $(TARGET_OUT_EXECUTABLES)/debuggerd
RECOVERY_BINARY_SOURCE_FILES    += $(TARGET_OUT_EXECUTABLES)/strace

# File systems
TARGET_USERIMAGES_USE_EXT4 := true
TARGET_USERIMAGES_USE_F2FS := true

# Kernel
BOARD_KERNEL_IMAGE_NAME     := bzImage
BOARD_BOOT_HEADER_VERSION   := 4
BOARD_KERNEL_PAGESIZE       := 4096
BOARD_MKBOOTIMG_ARGS        += --header_version $(BOARD_BOOT_HEADER_VERSION)
BOARD_MKBOOTIMG_ARGS        += --pagesize $(BOARD_KERNEL_PAGESIZE)

BOARD_RAMDISK_USE_LZ4       := true

# Partitions
BOARD_PROPERTY_OVERRIDES_SPLIT_ENABLED  := true
# Recovery partition size: 64 MiB (typical for goldfish)
BOARD_RECOVERYIMAGE_PARTITION_SIZE      := 0x4000000

# Super partition disabled — QEMU uses simple virtio-blk, no dynamic partitions

TARGET_COPY_OUT_VENDOR          := vendor
# Platform
TARGET_BOARD_PLATFORM   := goldfish
# Recovery
BOARD_EXCLUDE_KERNEL_FROM_RECOVERY_IMAGE    := true
TARGET_RECOVERY_PIXEL_FORMAT                := BGRA_8888
TW_INCLUDE_FASTBOOTD                        := false

# Tool
TW_ENABLE_ALL_PARTITION_TOOLS := true
TW_INCLUDE_REPACKTOOLS        := true
TW_INCLUDE_RESETPROP          := true
TW_INCLUDE_LIBRESETPROP       := true
TW_USE_TOOLBOX                := true
TW_INCLUDE_ZSTD               := true
TW_INCLUDE_7ZA                := true
TW_USE_DMCTL                  := true

# TWRP display
TW_THEME                    := portrait_hdpi
TW_FRAMERATE                := 60
TW_MAX_BRIGHTNESS           := 255
TW_DEFAULT_BRIGHTNESS       := 200
TW_NO_SCREEN_BLANK          := true
TW_NO_SCREEN_TIMEOUT        := true
TW_NO_USB_STORAGE           := true
TW_EXCLUDE_MTP              := true
TW_NO_BATT_PERCENT          := true
TW_EXCLUDE_DEFAULT_USB_INIT := true
TW_USE_LEGACY_BATTERY_SERVICES := true
TW_CUSTOM_BATTERY_PATH      := /sys/class/power_supply/battery
# Emulator uses virtio-gpu (drm), not fbdev
TW_USE_NEW_MINADBD          := true

# Disable vibrator
TW_NO_HAPTICS               := true

# TWRP file system
RECOVERY_SDCARD_ON_DATA     := true
TARGET_USES_MKE2FS          := true

# Security / Version bypass
# From build.prop:
#   ro.build.version.security_patch=2026-01-05
#   ro.build.version.release=16
# Keep these in sync to avoid decryption refusals.
PLATFORM_VERSION                := 16
PLATFORM_VERSION_LAST_STABLE    := $(PLATFORM_VERSION)
PLATFORM_SECURITY_PATCH         := 2026-01-05
VENDOR_SECURITY_PATCH           := $(PLATFORM_SECURITY_PATCH)
TW_DEVICE_VERSION               := GOOGLE-EMUX64

# Verified Boot
BOARD_AVB_ENABLE := true