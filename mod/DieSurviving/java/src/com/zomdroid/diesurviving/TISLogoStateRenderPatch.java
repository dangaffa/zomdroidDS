package com.zomdroid.diesurviving;

import me.zed_0xff.zombie_buddy.annotations.Patch;

/** Draws a whole screen centred on Core.getScreenWidth(); that should be the top screen. */
@Patch(className = "zombie.gameStates.TISLogoState", methodName = "render")
public class TISLogoStateRenderPatch {
    @Patch.OnEnter
    public static void enter() {
        if (DualScreen.ENABLED) DualScreen.enterWorldScope();
    }

    @Patch.OnExit
    public static void exit() {
        if (DualScreen.ENABLED) DualScreen.exitWorldScope();
    }
}
