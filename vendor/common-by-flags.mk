# Copyright (C) 2020 The LineageOS Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

LOCAL_PATH := device/nvidia/tegra-common/vendor

ifneq ("$(wildcard $(LOCAL_PATH)/$(TARGET_TEGRA_DOLBY)/ipprotect/ipprotect.mk)","")
$(call inherit-product, $(LOCAL_PATH)/$(TARGET_TEGRA_DOLBY)/ipprotect/ipprotect.mk)
endif

ifneq ("$(wildcard $(LOCAL_PATH)/$(TARGET_TEGRA_AUDIO)/audio/audio.mk)","")
$(call inherit-product, $(LOCAL_PATH)/$(TARGET_TEGRA_AUDIO)/audio/audio.mk)
endif

ifneq ("$(wildcard $(LOCAL_PATH)/$(TARGET_TEGRA_CAMERA)/camera/nvcamera.mk)","")
$(call inherit-product, $(LOCAL_PATH)/$(TARGET_TEGRA_CAMERA)/camera/nvcamera.mk)
endif

ifeq ($(NV_ANDROID_FRAMEWORK_ENHANCEMENTS),true)
ifneq ("$(wildcard $(LOCAL_PATH)/$(TARGET_TEGRA_DEFAULT_BRANCH)/nvcpl/nvcpl.mk)","")
$(call inherit-product, $(LOCAL_PATH)/$(TARGET_TEGRA_DEFAULT_BRANCH)/nvcpl/nvcpl.mk)
endif
endif

ifneq ("$(wildcard $(LOCAL_PATH)/$(TARGET_TEGRA_GPU)/nvgpu/nvgpu.mk)","")
$(call inherit-product, $(LOCAL_PATH)/$(TARGET_TEGRA_GPU)/nvgpu/nvgpu.mk)
endif

ifneq ("$(wildcard $(LOCAL_PATH)/$(TARGET_TEGRA_CEC)/hdmi/hdmi.mk)","")
$(call inherit-product, $(LOCAL_PATH)/$(TARGET_TEGRA_CEC)/hdmi/hdmi.mk)
endif

ifneq ("$(wildcard $(LOCAL_PATH)/$(TARGET_TEGRA_KEYSTORE)/keystore/keystore.mk)","")
$(call inherit-product, $(LOCAL_PATH)/$(TARGET_TEGRA_KEYSTORE)/keystore/keystore.mk)
$(call inherit-product, $(LOCAL_PATH)/$(TARGET_TEGRA_DEFAULT_BRANCH)/security/security.mk)
endif

ifneq ("$(wildcard $(LOCAL_PATH)/$(TARGET_TEGRA_MEMTRACK)/memtrack/memtrack.mk)","")
$(call inherit-product, $(LOCAL_PATH)/$(TARGET_TEGRA_MEMTRACK)/memtrack/memtrack.mk)
endif

ifneq ("$(wildcard $(LOCAL_PATH)/$(TARGET_TEGRA_OMX)/nvmm/nvmm.mk)","")
$(call inherit-product, $(LOCAL_PATH)/$(TARGET_TEGRA_OMX)/nvmm/nvmm.mk)
endif

ifneq ("$(wildcard $(LOCAL_PATH)/$(TARGET_TEGRA_PHS)/nvphs/nvphs.mk)","")
$(call inherit-product, $(LOCAL_PATH)/$(TARGET_TEGRA_PHS)/nvphs/nvphs.mk)
endif

ifneq ("$(wildcard $(LOCAL_PATH)/$(TARGET_TEGRA_POWER)/power/power.mk)","")
$(call inherit-product, $(LOCAL_PATH)/$(TARGET_TEGRA_POWER)/power/power.mk)
endif

ifneq ("$(wildcard $(LOCAL_PATH)/$(TARGET_TEGRA_WIDEVINE)/widevine/widevine.mk)","")
$(call inherit-product, $(LOCAL_PATH)/$(TARGET_TEGRA_WIDEVINE)/widevine/widevine.mk)
endif
