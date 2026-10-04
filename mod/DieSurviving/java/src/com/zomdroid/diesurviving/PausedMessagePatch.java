package com.zomdroid.diesurviving;

import me.zed_0xff.zombie_buddy.annotations.Patch;

/**
 * The "Game Paused" banner is drawn inside UIManager.render, centred on Core.getScreenWidth(). Its
 * block starts with isShowPausedMessage() and the statement right after it calls
 * isbFadeBeforeUI(), so a world scope between the two centres just the banner on the top screen.
 * Only inside UIManager.render: Lua (ISBackButtonWheel) calls isShowPausedMessage() too.
 */
public class PausedMessagePatch {
    public static final ThreadLocal<boolean[]> OPEN = ThreadLocal.withInitial(() -> new boolean[1]);
    public static final ThreadLocal<int[]> IN_RENDER = ThreadLocal.withInitial(() -> new int[1]);

    @Patch(className = "zombie.ui.UIManager", methodName = "render")
    public static class Render {
        @Patch.OnEnter
        public static void enter() {
            IN_RENDER.get()[0]++;
        }

        @Patch.OnExit
        public static void exit() {
            int[] depth = IN_RENDER.get();
            if (depth[0] > 0) depth[0]--;
        }
    }

    @Patch(className = "zombie.ui.UIManager", methodName = "isShowPausedMessage")
    public static class Open {
        @Patch.OnExit
        public static void exit(@Patch.Return boolean show) {
            boolean[] open = OPEN.get();
            if (DualScreen.ENABLED && show && !open[0] && IN_RENDER.get()[0] > 0) {
                open[0] = true;
                DualScreen.enterWorldScope();
            }
        }
    }

    @Patch(className = "zombie.ui.UIManager", methodName = "isbFadeBeforeUI")
    public static class Close {
        @Patch.OnEnter
        public static void enter() {
            boolean[] open = OPEN.get();
            if (open[0]) {
                open[0] = false;
                DualScreen.exitWorldScope();
            }
        }
    }
}
