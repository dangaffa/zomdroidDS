package com.zomdroid.diesurviving;

import me.zed_0xff.zombie_buddy.annotations.Patch;

/**
 * Sets up a player's viewport from Core.getScreenWidth(). Mark the call so that, on this thread
 * only, the screen width reads as the world width (see CoreScreenWidthPatch).
 */
@Patch(className = "zombie.core.Core", methodName = "DoStartFrameStuffInternal")
public class CoreDoStartFrameStuffInternalPatch {
    @Patch.OnEnter
    public static void enter(@Patch.Argument(3) int player) {
        if (DualScreen.ENABLED && player != -1) {
            DualScreen.IN_WORLD_FRAME.get()[0] = 1;
        }
    }

    @Patch.OnExit
    public static void exit(@Patch.Argument(3) int player) {
        if (DualScreen.ENABLED && player != -1) {
            DualScreen.IN_WORLD_FRAME.get()[0] = 0;
        }
    }
}
