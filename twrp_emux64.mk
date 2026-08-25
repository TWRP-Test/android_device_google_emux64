#
# Copyright (C) 2026 The Android Open Source Project
#
# SPDX-License-Identifier: Apache-2.0
#

DEVICE_PATH := device/google/emux64

# Inherit from device.mk configuration
$(call inherit-product, $(DEVICE_PATH)/device.mk)

## Device identifier
# Matches ro.product.system.name / ro.build.fingerprint device segment
PRODUCT_DEVICE   := emux64
PRODUCT_NAME     := twrp_emux64
PRODUCT_BRAND    := google
PRODUCT_MODEL    := Android SDK built for x86_64
PRODUCT_MANUFACTURER := Google