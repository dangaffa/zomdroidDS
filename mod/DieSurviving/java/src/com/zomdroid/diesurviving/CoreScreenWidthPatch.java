package com.zomdroid.diesurviving;

import me.zed_0xff.zombie_buddy.annotations.Patch;

/** Inside a world scope (see DualScreen.WORLD_SCOPE) the screen is the world region; elsewhere, the canvas. */
@Patch(className = "zombie.core.Core", methodName = "getScreenWidth")
public class CoreScreenWidthPatch {
    @Patch.OnExit
    public static void exit(@Patch.Return(readOnly = false) int width) {
        if (DualScreen.ENABLED && DualScreen.inWorldScope()) {
            width = DualScreen.worldWidth(width);
        }
    }
}
