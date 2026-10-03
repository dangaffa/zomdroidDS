package com.zomdroid.diesurviving;

import me.zed_0xff.zombie_buddy.annotations.Patch;
import zombie.characters.IsoPlayer;
import zombie.core.Core;

/** Before the offscreen buffer exists, Core reports the full canvas for the single player. */
@Patch(className = "zombie.core.Core", methodName = "getOffscreenWidth")
public class CoreOffscreenWidthPatch {
    @Patch.OnExit
    public static void exit(@Patch.Return(readOnly = false) int width) {
        if (DualScreen.ENABLED && IsoPlayer.numPlayers <= 1 && width == Core.width) {
            width = DualScreen.worldWidth(Core.width);
        }
    }
}
