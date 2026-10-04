package com.zomdroid.diesurviving;

import me.zed_0xff.zombie_buddy.annotations.Patch;

/** The startup epilepsy warning is centred on Core.getScreenWidth(); centre it on the top screen. */
@Patch(className = "zombie.GameWindow", methodName = "doEpilepsyWarningText")
public class EpilepsyWarningPatch {
    @Patch.OnEnter
    public static void enter() {
        if (DualScreen.ENABLED) DualScreen.enterWorldScope();
    }

    @Patch.OnExit
    public static void exit() {
        if (DualScreen.ENABLED) DualScreen.exitWorldScope();
    }
}
