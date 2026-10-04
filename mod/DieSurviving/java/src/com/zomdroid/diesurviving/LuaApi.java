package com.zomdroid.diesurviving;

import se.krka.kahlua.integration.annotations.LuaMethod;

/** Global Lua functions for the DieSurviving Lua side. */
public class LuaApi {
    /**
     * Width of the world region (top screen) for a canvas of the given width, or 0 when the game
     * runs on a single screen.
     */
    @LuaMethod(name = "DieSurviving_worldWidth", global = true)
    public static double worldWidth(double canvasWidth) {
        return DualScreen.ENABLED ? DualScreen.worldWidth((int) canvasWidth) : 0;
    }

    /**
     * Run Lua drawing code in a world scope: getCore():getScreenWidth() reports the top screen's
     * width until the matching DieSurviving_exitWorldScope(). Always pair them (use pcall).
     */
    @LuaMethod(name = "DieSurviving_enterWorldScope", global = true)
    public static void enterWorldScope() {
        if (DualScreen.ENABLED) DualScreen.enterWorldScope();
    }

    @LuaMethod(name = "DieSurviving_exitWorldScope", global = true)
    public static void exitWorldScope() {
        if (DualScreen.ENABLED) DualScreen.exitWorldScope();
    }
}
