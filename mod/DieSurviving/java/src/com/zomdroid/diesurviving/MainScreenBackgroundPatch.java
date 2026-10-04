package com.zomdroid.diesurviving;

import me.zed_0xff.zombie_buddy.annotations.Patch;

/** The main menu's painting fills Core.getScreenWidth(); keep it on the top screen. */
@Patch(className = "zombie.gameStates.MainScreenState", methodName = "renderBackground")
public class MainScreenBackgroundPatch {
    @Patch.OnEnter
    public static void enter() {
        if (DualScreen.ENABLED) DualScreen.enterWorldScope();
    }

    @Patch.OnExit
    public static void exit() {
        if (DualScreen.ENABLED) DualScreen.exitWorldScope();
    }
}
