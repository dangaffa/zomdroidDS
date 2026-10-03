package com.zomdroid.dualscreen;

import android.app.Activity;
import android.app.Presentation;
import android.content.Context;
import android.content.SharedPreferences;
import android.hardware.display.DisplayManager;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.util.Log;
import android.view.Display;
import android.view.SurfaceHolder;
import android.view.SurfaceView;
import android.view.WindowManager;

import androidx.annotation.NonNull;

import com.zomdroid.C;
import com.zomdroid.GameLauncher;

/**
 * Dual-screen mode: shows a {@link Presentation} with a full-size {@link SurfaceView} on the
 * secondary (bottom) display and hands its surface to native code, which presents part of the
 * game frame there. Does nothing on devices without a presentation display.
 */
public class BottomScreen {
    private static final String LOG_TAG = "ZomdroidDS";
    /** Shared pref (in {@link C.shprefs#NAME}); dual-screen mode is on unless this is false. */
    public static final String PREF_ENABLED = "dual_screen_enabled";

    private final Activity activity;
    private final DisplayManager displayManager;
    private Presentation presentation;
    private int displayId = Display.INVALID_DISPLAY;

    private final DisplayManager.DisplayListener displayListener = new DisplayManager.DisplayListener() {
        @Override
        public void onDisplayAdded(int id) {
            if (presentation == null) show();
        }

        @Override
        public void onDisplayRemoved(int id) {
            if (id == displayId) {
                Log.i(LOG_TAG, "Bottom display " + id + " removed");
                dismiss();
            }
        }

        @Override
        public void onDisplayChanged(int id) {
        }
    };

    public BottomScreen(Activity activity) {
        this.activity = activity;
        this.displayManager = activity.getSystemService(DisplayManager.class);
    }

    public static boolean isEnabled(Context context) {
        SharedPreferences prefs = context.getSharedPreferences(C.shprefs.NAME, Context.MODE_PRIVATE);
        return prefs.getBoolean(PREF_ENABLED, true);
    }

    public void start() {
        displayManager.registerDisplayListener(displayListener, new Handler(Looper.getMainLooper()));
        show();
    }

    public void stop() {
        displayManager.unregisterDisplayListener(displayListener);
        dismiss();
    }

    private Display findDisplay() {
        for (Display display : displayManager.getDisplays(DisplayManager.DISPLAY_CATEGORY_PRESENTATION)) {
            if (display.getDisplayId() != Display.DEFAULT_DISPLAY) return display;
        }
        return null;
    }

    private void show() {
        Display display = findDisplay();
        if (display == null) {
            Log.i(LOG_TAG, "No presentation display, staying single-screen");
            return;
        }
        displayId = display.getDisplayId();
        Log.i(LOG_TAG, "Showing bottom screen on display " + displayId);
        presentation = new BottomPresentation(activity, display);
        presentation.setOnDismissListener(d -> {
            if (presentation == d) {
                presentation = null;
                displayId = Display.INVALID_DISPLAY;
            }
        });
        try {
            presentation.show();
        } catch (WindowManager.InvalidDisplayException e) {
            Log.w(LOG_TAG, "Bottom display went away before the presentation could show", e);
            presentation = null;
            displayId = Display.INVALID_DISPLAY;
        }
    }

    private void dismiss() {
        if (presentation != null) {
            Presentation p = presentation;
            presentation = null;
            displayId = Display.INVALID_DISPLAY;
            p.dismiss();
        }
    }

    private static class BottomPresentation extends Presentation {
        BottomPresentation(Context outerContext, Display display) {
            super(outerContext, display);
        }

        @Override
        protected void onCreate(Bundle savedInstanceState) {
            super.onCreate(savedInstanceState);
            // Keep key/gamepad focus on the game window on the top display.
            getWindow().addFlags(WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE
                    | WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
            SurfaceView surfaceView = new SurfaceView(getContext());
            surfaceView.getHolder().addCallback(new SurfaceHolder.Callback() {
                @Override
                public void surfaceCreated(@NonNull SurfaceHolder holder) {
                }

                @Override
                public void surfaceChanged(@NonNull SurfaceHolder holder, int format, int width, int height) {
                    Log.i(LOG_TAG, "Bottom surface " + width + "x" + height);
                    GameLauncher.setBottomSurface(holder.getSurface(), width, height);
                }

                @Override
                public void surfaceDestroyed(@NonNull SurfaceHolder holder) {
                    Log.i(LOG_TAG, "Bottom surface destroyed");
                    GameLauncher.destroyBottomSurface();
                }
            });
            setContentView(surfaceView);
        }
    }
}
