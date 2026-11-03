LOCAL_PATH := $(call my-dir)

include $(CLEAR_VARS)
LOCAL_MODULE := vndk_v29_symlinks
LOCAL_LICENSE_KINDS := SPDX-license-identifier-Apache-2.0
LOCAL_LICENSE_CONDITIONS := notice
LOCAL_NOTICE_FILE := build/soong/licenses/LICENSE
LOCAL_MODULE_CLASS := ETC
LOCAL_SRC_FILES := Android.mk
LOCAL_MODULE_PATH := $(TARGET_OUT)/etc
LOCAL_POST_INSTALL_CMD := \
    mkdir -p $(TARGET_OUT)/lib $(TARGET_OUT)/lib64 && \
    ln -sf /apex/com.android.vndk.v29/lib $(TARGET_OUT)/lib/vndk-29 && \
    ln -sf /apex/com.android.vndk.v29/lib $(TARGET_OUT)/lib/vndk-sp-29 && \
    ln -sf /apex/com.android.vndk.v29/lib64 $(TARGET_OUT)/lib64/vndk-29 && \
    ln -sf /apex/com.android.vndk.v29/lib64 $(TARGET_OUT)/lib64/vndk-sp-29
include $(BUILD_PREBUILT)
