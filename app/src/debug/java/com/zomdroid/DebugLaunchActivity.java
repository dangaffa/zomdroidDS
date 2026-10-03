package com.zomdroid;

import android.app.Activity;
import android.content.Intent;
import android.os.Bundle;
import android.util.Log;

import com.zomdroid.game.BackupManager;
import com.zomdroid.game.GameInstance;
import com.zomdroid.game.GameInstanceManager;

/**
 * Debug-only entry point so a game instance can be started from the shell without tapping Play:
 *
 *   adb shell am start -n com.zomdroid.ds/com.zomdroid.DebugLaunchActivity [--es instance NAME]
 *
 * Without the extra, the first fully installed instance is launched.
 */
public class DebugLaunchActivity extends Activity {
    private static final String LOG_TAG = "DebugLaunch";
    public static final String EXTRA_INSTANCE = "instance";

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        GameInstance instance = pickInstance(getIntent().getStringExtra(EXTRA_INSTANCE));
        if (instance == null) {
            Log.e(LOG_TAG, "No installed game instance to launch");
        } else {
            Log.i(LOG_TAG, "Launching instance " + instance.getName());
            BackupManager.cleanupInterruptedRestore(instance);
            Intent intent = new Intent(this, GameActivity.class);
            intent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TASK);
            intent.putExtra(GameActivity.EXTRA_GAME_INSTANCE_NAME, instance.getName());
            startActivity(intent);
        }
        finish();
    }

    private static GameInstance pickInstance(String name) {
        GameInstanceManager manager = GameInstanceManager.requireSingleton();
        if (name != null) return manager.getInstanceByName(name);
        for (GameInstance instance : manager.getInstances()) {
            if (instance.isInstallationFinished()) return instance;
        }
        return null;
    }
}
