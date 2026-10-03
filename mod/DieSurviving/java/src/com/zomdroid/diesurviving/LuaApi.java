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
}
