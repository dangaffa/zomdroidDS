package com.zomdroid.diesurviving;

import me.zed_0xff.zombie_buddy.annotations.Patch;
import zombie.characters.IsoPlayer;
import zombie.core.Core;

/**
 * Player 0's view is the world region, not the whole canvas. Camera centring, the world
 * offscreen buffer size and mouse picking all derive from this.
 */
@Patch(className = "zombie.iso.IsoCamera", methodName = "getScreenWidth")
public class IsoCameraScreenWidthPatch {
    @Patch.OnExit
    public static void exit(@Patch.Return(readOnly = false) int width) {
        if (DualScreen.ENABLED && IsoPlayer.numPlayers <= 1) {
            width = DualScreen.worldWidth(Core.width);
        }
    }
}
