/*
 * gaea 预装器（GaeaPreinstaller）
 *
 * 为什么需要这个 App：
 *   GCam 是 PairIP 加固的，libgcastartup.so 需要 execmod。
 *   AOSP neverallow 只豁免 apk_data_file / app_data_file / asec_public_file，
 *   所以它不能放 /system/app（system_file 必然被拒），只能装进 /data/app。
 *
 * 为什么不用 init service + pm install：
 *   init 域不能执行 /system/bin/sh（init.te 只有 vendor_shell_exec），
 *   自建 SELinux 域跑 cmd package 要补一整条权限链补不完，
 *   借 shell 域又等于给开机 root 脚本全开权限，审不过。
 *
 * 正确做法就是 OEM 的做法：平台签名的 priv-app + PackageInstaller API。
 *   域：priv_app（seapp_contexts: user=_app isPrivApp=true domain=priv_app）
 *   权限：INSTALL_PACKAGES（signature|privileged，priv-app 自动获得）
 *   package_service 带 app_api_service 属性，priv_app.te:35 已有 find 授权
 *   不需要新增任何 SELinux 规则
 */

package com.gaea.preinstaller;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageInstaller;
import android.content.pm.PackageManager;
import android.util.Log;

import java.io.File;
import java.io.FileInputStream;
import java.io.InputStream;
import java.io.OutputStream;

/**
 * 监听 BOOT_COMPLETED，把 /system/preinstall/*.apk.bin 装进 /data/app。
 *
 * 用 receiver 而不是 Activity：Activity 无法开机自启，
 * receiver 由 system_server 直接拉起，不依赖任何 init 脚本。
 */
public class BootReceiver extends BroadcastReceiver {
    private static final String TAG = "GaeaPreinstaller";

    /** APK 存放目录，由 device.mk 的 PRODUCT_COPY_FILES 铺进去 */
    private static final String SRC_DIR = "/system/preinstall";

    /**
     * 装完后写这个标记文件，避免每次开机重复扫描。
     *
     * 为什么不用属性：
     *   sys.* 前缀重启后被清空；persist.* 需要额外的 property_contexts
     *   和 SELinux 写权限。文件标记不需要任何权限，App 私有目录重启不丢。
     */
    private static final String MARKER_NAME = "preinstall_done";

    @Override
    public void onReceive(Context context, Intent intent) {
        if (!Intent.ACTION_BOOT_COMPLETED.equals(intent.getAction())) {
            return;
        }

        File marker = markerFile(context);
        if (marker.exists()) {
            Log.i(TAG, "marker exists (" + marker + "), skip");
            return;
        }
        Log.i(TAG, "marker missing (" + marker + "), proceed");

        // receiver 有 10 秒超时，必须丢到后台线程
        new Thread(() -> installAll(context.getApplicationContext()),
                "gaea-preinstall").start();
    }

    private void installAll(Context ctx) {
        // BOOT_COMPLETED 时 PackageManager 可能还没扫完 /data/app，
        // 等 8 秒避免 isInstalled() 误判为未装、导致每次开机重装 326 MB。
        try {
            Thread.sleep(8000);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            return;
        }

        File dir = new File(SRC_DIR);
        File[] apks = dir.listFiles((d, name) -> name.endsWith(".apk.bin"));
        if (apks == null || apks.length == 0) {
            Log.w(TAG, "no apk found in " + SRC_DIR);
            writeMarker(ctx);
            return;
        }

        for (File apk : apks) {
            try {
                installOne(ctx, apk);
            } catch (Exception e) {
                Log.e(TAG, "install failed: " + apk, e);
            }
        }

        writeMarker(ctx);
        Log.i(TAG, "all done");
    }

    private void installOne(Context ctx, File apk) throws Exception {
        PackageManager pm = ctx.getPackageManager();

        // 包名解析：PackageParser.parseApkLiteInner 走 ApkAssets.loadFromPath，
        // 直接按 zip 读 AndroidManifest，不检查扩展名，所以 .apk.bin 也能解析。
        String pkgName = readPackageName(pm, apk);
        if (pkgName == null) {
            Log.w(TAG, "cannot read package name from " + apk);
            return;
        }
        if (isInstalled(pm, pkgName)) {
            Log.i(TAG, pkgName + " already installed, skip");
            return;
        }

        PackageInstaller installer = pm.getPackageInstaller();
        PackageInstaller.SessionParams params =
                new PackageInstaller.SessionParams(
                        PackageInstaller.SessionParams.MODE_FULL_INSTALL);

        // 自动授予运行时权限，免掉首次启动的授权弹窗。
        // 对应 pm install -g 的行为（v26 用 shell 跑 pm install -g 时无弹窗）。
        // 只列 GCam 真正需要的；不存在的权限会被系统忽略，不会报错。
        params.setGrantedRuntimePermissions(new String[]{
                android.Manifest.permission.CAMERA,
                android.Manifest.permission.RECORD_AUDIO,
                android.Manifest.permission.ACCESS_FINE_LOCATION,
                android.Manifest.permission.ACCESS_COARSE_LOCATION,
                // A13 用媒体细分权限，旧的 READ/WRITE_EXTERNAL_STORAGE 在 targetSdk 33+ 无效
                android.Manifest.permission.READ_MEDIA_IMAGES,
                android.Manifest.permission.READ_MEDIA_VIDEO,
        });

        int sessionId = installer.createSession(params);
        try (PackageInstaller.Session session = installer.openSession(sessionId)) {
            try (InputStream in = new FileInputStream(apk);
                 OutputStream out = session.openWrite("base.apk", 0, apk.length())) {
                byte[] buf = new byte[1024 * 1024];
                int n;
                while ((n = in.read(buf)) > 0) {
                    out.write(buf, 0, n);
                }
                session.fsync(out);
            }
            session.commit(InstallResultReceiver.getIntentSender(ctx, sessionId));
        }

        Log.i(TAG, "commit sent for " + apk.getName() + " (" + pkgName + ")");
    }

    /**
     * 标记文件必须放设备加密（DE）存储，不能放 CE。
     *
     * 本 App 是 directBootAware，BOOT_COMPLETED 时用户还没解锁，
     * /data/user/0/（CE）尚未挂载，getFilesDir() 拿到的路径不可写。
     * DE 存储（/data/user_de/0/）在开机早期就可用。
     */
    private File markerFile(Context ctx) {
        return new File(ctx.createDeviceProtectedStorageContext().getFilesDir(),
                MARKER_NAME);
    }

    private void writeMarker(Context ctx) {
        try {
            File marker = markerFile(ctx);
            File dir = marker.getParentFile();
            if (dir != null && !dir.exists() && !dir.mkdirs()) {
                Log.w(TAG, "cannot create " + dir);
                return;
            }
            if (marker.createNewFile()) {
                Log.i(TAG, "marker written: " + marker);
            }
        } catch (Exception e) {
            Log.w(TAG, "writeMarker failed", e);
        }
    }

    private boolean isInstalled(PackageManager pm, String pkg) {
        try {
            pm.getPackageInfo(pkg, 0);
            Log.i(TAG, "isInstalled(" + pkg + ") = true");
            return true;
        } catch (PackageManager.NameNotFoundException e) {
            Log.i(TAG, "isInstalled(" + pkg + ") = false (NameNotFound)");
            return false;
        } catch (Exception e) {
            // 其他异常不能当成"未装"，否则会重装 326 MB
            Log.w(TAG, "isInstalled(" + pkg + ") threw " + e.getClass().getSimpleName()
                    + ", assume installed to be safe", e);
            return true;
        }
    }

    private String readPackageName(PackageManager pm, File apk) {
        try {
            android.content.pm.PackageInfo info =
                    pm.getPackageArchiveInfo(apk.getAbsolutePath(), 0);
            return info == null ? null : info.packageName;
        } catch (Exception e) {
            Log.w(TAG, "readPackageName failed for " + apk, e);
            return null;
        }
    }
}
