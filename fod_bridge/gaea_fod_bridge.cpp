/*
 * Copyright (C) 2026 The LineageOS Project
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#define LOG_TAG "gaea_fod_bridge"

#include <dirent.h>
#include <errno.h>
#include <fcntl.h>
#include <linux/input.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/ioctl.h>
#include <sys/poll.h>
#include <time.h>
#include <unistd.h>

#include <log/log.h>

#include <android/hidl/base/1.0/IBase.h>
#include <android/hidl/manager/1.0/IServiceManager.h>
#include <hidl/HidlBinderSupport.h>
#include <hidl/ServiceManagement.h>
#include <hwbinder/IBinder.h>
#include <hwbinder/Parcel.h>

using android::sp;
using android::status_t;
using android::hardware::defaultServiceManager;
using android::hardware::IBinder;
using android::hardware::Parcel;
using android::hardware::toBinder;
using android::hidl::base::V1_0::IBase;
using android::hidl::manager::V1_0::IServiceManager;

#define KEY_FOD_DOWN 508
#define KEY_FOD_UP   509

static sp<IBinder> gBinder = nullptr;

static bool getService() {
    auto sm = defaultServiceManager();
    if (!sm) {
        ALOGE("defaultServiceManager is null");
        return false;
    }
    sp<IBase> base = sm->get("vendor.yulong.fingerprintevent@1.0::IFingerprintEvent", "default");
    if (!base) {
        ALOGW("vendor.yulong.fingerprintevent@1.0::IFingerprintEvent not available yet");
        return false;
    }
    gBinder = toBinder(base);
    if (!gBinder) {
        ALOGE("Failed to convert IBase to IBinder");
        return false;
    }
    ALOGI("Connected to vendor.yulong.fingerprintevent@1.0::IFingerprintEvent");
    return true;
}

static void sendCommand(int cmd, int arg) {
    if (!gBinder && !getService()) {
        ALOGE("sendCommand(%d, %d) failed: no binder", cmd, arg);
        return;
    }
    Parcel data, reply;
    data.writeInterfaceToken("vendor.yulong.fingerprintevent@1.0::IFingerprintEvent");
    data.writeUint32(arg);
    status_t res = gBinder->transact(cmd, data, &reply, 0);
    if (res != android::OK) {
        ALOGW("transact cmd=%d arg=%d failed: %d, dropping binder", cmd, arg, res);
        gBinder = nullptr;
    } else {
        ALOGI("sendCommand cmd=%d arg=%d success", cmd, arg);
    }
}

static inline void setHbm(int mode) {
    sendCommand(2, mode);
}

static inline void downOrUp(int state) {
    sendCommand(1, state);
}

static int openFtsTouchDevice() {
    char devname[64];
    char name[128];
    for (int i = 0; i < 32; i++) {
        snprintf(devname, sizeof(devname), "/dev/input/event%d", i);
        int fd = open(devname, O_RDONLY | O_NONBLOCK);
        if (fd < 0) continue;
        memset(name, 0, sizeof(name));
        if (ioctl(fd, EVIOCGNAME(sizeof(name)), name) >= 0) {
            if (strcmp(name, "fts_ts") == 0) {
                ALOGI("Found fts_ts at %s", devname);
                return fd;
            }
        }
        close(fd);
    }
    return -1;
}

int main(int argc, char** argv) {
    (void)argc;
    (void)argv;
    ALOGI("Starting gaea_fod_bridge daemon...");

    // Retry connecting to service
    while (!getService()) {
        sleep(1);
    }
    // Enable touchscreen FOD gesture mode
    setHbm(4);

    int touch_fd = -1;
    bool is_pressed = false;
    time_t last_press_time = 0;

    while (true) {
        if (touch_fd < 0) {
            touch_fd = openFtsTouchDevice();
            if (touch_fd < 0) {
                ALOGW("Waiting for fts_ts input device...");
                sleep(2);
                continue;
            }
        }

        struct pollfd pfd;
        pfd.fd = touch_fd;
        pfd.events = POLLIN;

        int ret = poll(&pfd, 1, 1000);
        if (ret < 0) {
            if (errno == EINTR) continue;
            ALOGE("poll error: %d (%s)", errno, strerror(errno));
            close(touch_fd);
            touch_fd = -1;
            continue;
        }

        time_t now = time(nullptr);
        // Watchdog: If pressed for > 5s without release, force reset
        if (is_pressed && (now - last_press_time > 5)) {
            ALOGW("FOD press watchdog timeout (>5s), forcing release");
            downOrUp(0);
            setHbm(0);
            is_pressed = false;
        }

        if (ret == 0) {
            continue;
        }

        if (pfd.revents & (POLLERR | POLLHUP | POLLNVAL)) {
            ALOGW("Input fd error/hup, reopening...");
            close(touch_fd);
            touch_fd = -1;
            continue;
        }

        if (pfd.revents & POLLIN) {
            struct input_event ev[16];
            int bytes = read(touch_fd, ev, sizeof(ev));
            if (bytes < (int)sizeof(struct input_event)) {
                if (bytes < 0 && errno != EAGAIN) {
                    close(touch_fd);
                    touch_fd = -1;
                }
                continue;
            }

            int count = bytes / sizeof(struct input_event);
            for (int i = 0; i < count; i++) {
                if (ev[i].type == EV_KEY) {
                    if (ev[i].code == KEY_FOD_DOWN && ev[i].value == 1) {
                        if (!is_pressed) {
                            ALOGI("KEY_FOD_DOWN detected -> setHbm(1) + downOrUp(1)");
                            setHbm(1);
                            downOrUp(1);
                            is_pressed = true;
                            last_press_time = time(nullptr);
                        }
                    } else if (ev[i].code == KEY_FOD_UP && ev[i].value == 1) {
                        if (is_pressed) {
                            ALOGI("KEY_FOD_UP detected -> downOrUp(0) + setHbm(0)");
                            downOrUp(0);
                            setHbm(0);
                            is_pressed = false;
                        }
                    }
                }
            }
        }
    }

    return 0;
}
