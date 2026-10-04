package com.zomdroid.diesurviving;

public class Main {
    public static void main(String[] args) {
        System.out.println("[DieSurviving] loaded, dual screen " + (DualScreen.ENABLED
                ? "on, world fraction " + DualScreen.WORLD_FRACTION
                : "off"));
        // Debug aid: an empty file named ds-old-renderer in the instance home turns off B42's chunk
        // texture renderer (same as the debug "toggle old renderer" key), for renderer A/B tests.
        if (new java.io.File(System.getProperty("user.home"), "ds-old-renderer").exists()) {
            zombie.core.PerformanceSettings.fboRenderChunk = false;
            System.out.println("[DieSurviving] chunk texture renderer OFF (ds-old-renderer)");
        }
        // Debug aid: add -Dzomdroid.ds.debugMouse=true to the JVM args to log mouse state changes.
        if (Boolean.getBoolean("zomdroid.ds.debugMouse")) {
            Thread t = new Thread(() -> {
                int lx = -1, ly = -1;
                boolean ld = false;
                while (true) {
                    int x = zombie.input.Mouse.getXA(), y = zombie.input.Mouse.getYA();
                    boolean d = zombie.input.Mouse.isButtonDown(0);
                    if (x != lx || y != ly || d != ld) {
                        System.out.println("[DieSurviving] mouse " + x + "," + y + " down=" + d
                                + " display=" + org.lwjglx.opengl.Display.getWidth() + "x"
                                + org.lwjglx.opengl.Display.getHeight()
                                + " core=" + zombie.core.Core.width + "x" + zombie.core.Core.height);
                        lx = x; ly = y; ld = d;
                    }
                    try { Thread.sleep(20); } catch (InterruptedException e) { return; }
                }
            }, "DieSurvivingMouseDebug");
            t.setDaemon(true);
            t.start();
        }
    }
}
