package com.gaea.preinstaller;

import android.app.PendingIntent;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageInstaller;
import android.util.Log;

/** 收 PackageInstaller 的安装结果，只记日志。 */
public class InstallResultReceiver extends BroadcastReceiver {
    private static final String TAG = "GaeaPreinstaller";
    private static final String ACTION_INSTALL_RESULT =
            "com.gaea.preinstaller.INSTALL_RESULT";

    static android.content.IntentSender getIntentSender(Context ctx, int sessionId) {
        Intent intent = new Intent(ACTION_INSTALL_RESULT).setPackage(ctx.getPackageName());
        return PendingIntent.getBroadcast(ctx, sessionId, intent,
                PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_MUTABLE)
                .getIntentSender();
    }

    @Override
    public void onReceive(Context context, Intent intent) {
        int status = intent.getIntExtra(PackageInstaller.EXTRA_STATUS,
                PackageInstaller.STATUS_FAILURE);
        String msg = intent.getStringExtra(PackageInstaller.EXTRA_STATUS_MESSAGE);
        if (status == PackageInstaller.STATUS_SUCCESS) {
            Log.i(TAG, "install success: " + msg);
        } else {
            Log.e(TAG, "install failed, status=" + status + " msg=" + msg);
        }
    }
}
