package com.zomdroid.diesurviving;

/**
 * Dual-screen layout shared by the patches.
 *
 * <p>The launcher gives the game one wide canvas: the top screen on the left, the bottom screen to
 * its right. It passes {@code -Dzomdroid.ds.worldFraction=<top width / canvas width>}; the world is
 * confined to that left fraction and the strip to the right is left for UI. Without the property
 * (single screen, or dual-screen turned off) every patch is a no-op.
 */
public final class DualScreen {
    public static final float WORLD_FRACTION = parseFraction(System.getProperty("zomdroid.ds.worldFraction"));
    public static final boolean ENABLED = WORLD_FRACTION > 0f && WORLD_FRACTION < 1f;

    /**
     * Non-zero while the current thread is in a "world scope": code that sizes or centres things on
     * the screen but means the top screen (a player's world viewport, the loading screen, the
     * "Game Paused" banner...). There {@code Core.getScreenWidth()} reports the world width; the
     * full canvas everywhere else. A counter, so scopes can nest.
     */
    public static final ThreadLocal<int[]> WORLD_SCOPE = ThreadLocal.withInitial(() -> new int[1]);

    public static void enterWorldScope() {
        WORLD_SCOPE.get()[0]++;
    }

    public static void exitWorldScope() {
        int[] depth = WORLD_SCOPE.get();
        if (depth[0] > 0) depth[0]--;
    }

    public static boolean inWorldScope() {
        return WORLD_SCOPE.get()[0] > 0;
    }

    private DualScreen() {
    }

    /** Width of the world region for a canvas of the given width. */
    public static int worldWidth(int canvasWidth) {
        return Math.round(canvasWidth * WORLD_FRACTION);
    }

    private static float parseFraction(String value) {
        if (value == null) return 0f;
        try {
            return Float.parseFloat(value);
        } catch (NumberFormatException e) {
            return 0f;
        }
    }
}
