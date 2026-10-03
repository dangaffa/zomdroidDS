package com.zomdroid.diesurviving;

import me.zed_0xff.zombie_buddy.annotations.Patch;

/** Inside a player's viewport setup, the screen is the world region. Everywhere else, the canvas. */
@Patch(className = "zombie.core.Core", methodName = "getScreenWidth")
public class CoreScreenWidthPatch {
    @Patch.OnExit
    public static void exit(@Patch.Return(readOnly = false) int width) {
        if (DualScreen.ENABLED && DualScreen.IN_WORLD_FRAME.get()[0] != 0) {
            width = DualScreen.worldWidth(width);
        }
    }
}
