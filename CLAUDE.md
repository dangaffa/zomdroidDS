# Project Zomboid: Die Surviving

A dual-screen fork of [Zomdroid](https://github.com/udarmolota/zomdroid) (an unofficial Project Zomboid launcher for Android) for the **AYN Thor**. The game world renders on the top screen; nearly every interactive menu (inventory, crafting, map, health, character info, containers, and so on) opens on the bottom touchscreen instead of as a window over the game.

Target: **Project Zomboid Build 42**. Build 41 is out of scope.

## Workspace layout

All under `C:/Users/minec/Documents/GitHub/`:

- `zomdroidDS/`: this repo, a fork of `udarmolota/zomdroid` (`origin` = `dangaffa/zomdroidDS`, `upstream` = udarmolota). Work branch: `dual-screen`.
- `zomdroidDS/app/src/main/cpp/glfw`: submodule pointing at `dangaffa/zomdroidDS-glfw`, branch `dual-screen` (cut from upstream's `ng` commit that Zomdroid pinned). `zomdroidDS-glfw/` next to this repo is a standalone clone of the same fork.
- `zomboidDS/`: not a repo. Holds the original project brief (`CLAUDE.md`), and `support/`: a Linux PZ B42 depot (`support/depots/108603/25485521/projectzomboid`, used for decompiling) and the ZombieBuddy source (`support/ZombieBuddy-master`). Helper scripts write logs and screenshots to `zomboidDS/logs` and `zomboidDS/shots`. Put decompiled code in `zomboidDS/reference/decompiled/`.
- `zomdroid/`, `zomdroid-glfw/`: plain upstream clones. Leave them alone.

## How you work in this repo

You (Claude) run the full loop yourself: edit code, build, install on the Thor over ADB, launch, read logs, and screenshot both screens. Do not ask the user to run commands you can run. Ask the user only when you need something physical (tapping through a menu you can't reach, approving a prompt on the device, plugging the device in) or before anything destructive (see "Rules").

After every on-device test, report briefly: what changed, what you saw on each screen, and what you'll try next.

## Hardware facts

- **Top screen:** 6" AMOLED, 1920x1080, 120 Hz. Android treats this as the **primary** display (display 0).
- **Bottom screen:** 3.92" AMOLED, 1240x1080, 60 Hz, touch. This is a **secondary** display.
- **SoC:** Snapdragon 8 Gen 2 (Adreno 740) on Base/Pro/Max; Snapdragon 865 on the Lite.
- Physical gamepad controls are built in, so on-screen movement controls are not the priority.

Display IDs are not stable across devices. Discover them once and record them below:

```
adb shell dumpsys display | grep -E "mDisplayId|uniqueId|DisplayDeviceInfo"
adb shell dumpsys SurfaceFlinger --display-id
```

<!-- Fill these in on first run -->
- Logical display ID, top: `0`
- Logical display ID, bottom: `4`
- Physical (SurfaceFlinger) ID, top: `4630946441858561667` (port 131, "Built-in Screen")
- Physical (SurfaceFlinger) ID, bottom: `4630946482288158084` (port 132, "Screen-2", has `FLAG_PRESENTATION`)

Recorded on the user's Thor Max (2026-10-03). Both panels are natively portrait and run rotated to landscape (`orientation=1`). The bottom panel also offers a 120 Hz mode, but it defaults to 60 Hz.

## Architecture: the wide virtual canvas

The game only knows one window. We tell it that window is both screens **side by side**, then split the output. The canvas is the top screen's width plus the bottom screen's width scaled to the top screen's height: 1920 + 1240 = 3160 x 1080 on the Thor, at render scale 1. Side by side, not stacked: the world keeps a 16:9 region of its own (the left part, shown on the top screen), the strip on the right is for menus, and any dual-screen device whose second screen is about as tall as the first (Retroid Pocket Duo and so on) fits the same scheme. Decided with the user on 2026-10-03; it replaced the original "tall canvas" plan.

1. **Android layer** (`app/src/main/java/com/zomdroid`). `dualscreen/BottomScreen` finds the secondary display via `DisplayManager`, shows a `Presentation` on it containing a `SurfaceView`, and hands that surface to native code (`GameLauncher.setBottomSurface`). `GameActivity` widens the game `SurfaceView` past the right edge of the top display with a negative right margin (`BottomScreen.extraCanvasWidth`); the part past the edge is clipped by the window, but the game renders it. Touches on the bottom screen will become mouse input with x offset by the top region's width.
2. **Native layer** (`app/src/main/cpp/glfw`, a submodule pointing at our fork of `zomdroid-glfw`). At each frame the rightmost strip of the canvas (bottom display's aspect ratio, full canvas height) is read back and pushed to the bottom window (`src/zomdroid_dualscreen.c`). The bottom window's buffers are sized to the strip, so the compositor scales it to the display, render scale included.
3. **Java mod via ZombieBuddy** (`mod/DieSurviving/.../media/java`). ByteBuddy `@Patch` classes that restrict player 0's camera (`zombie.iso.IsoCamera` screen/offscreen region methods) to the left (top-screen) region and keep the mouse and UI working across the whole canvas.
4. **Lua mod** (`mod/DieSurviving/.../media/lua`). Catches windows as they're created (`ISCollapsableWindow`, `ISPanel`, and so on, hooked at `addToUIManager` or construction) and places them in the right (bottom-screen) region by default. Keeps an exclusion list for things that must stay on top: HUD, tooltips, on-world overlays, the main menu. Context menus (`ISContextMenu`) are an open design question; decide during testing.

### Renderer paths

The GLFW fork has three separate present paths, all of which need the split eventually:

- `src/egl_context.c`: EGL (GL4ES renderers). Swap is in `swapBuffersEGL`; surface recreation uses `g_zomdroid_surface`.
- `src/zfa_context.c`: ZFA (Zink, ZINK_ZFA). `libzfa.so` is a separate Mesa build (not in these repos) that presents to exactly one `ANativeWindow` itself. **This is the path we use.** The bottom screen is fed by GL read-back in `src/zomdroid_dualscreen.c`: `glReadPixels` into a PBO before the frame's `glFinish()`, map and copy into a CPU staging slot after it, and a worker thread pushes the newest slot to the bottom window with `ANativeWindow_lock`.
- `src/osmesa_context.c`: OSMesa (Zink, ZINK_OSMESA). Software buffer locked via `ANativeWindow_lock`, so the bottom copy is a plain memory copy.

**Pick one renderer first** (whichever runs B42 best on the Thor — check with the user) and get it fully working before touching the others. Record the choice here:

- Primary renderer: `ZINK_ZFA` (the installer's "Build 42 (quality)" preset on Adreno; Mesa Zink on Turnip, present path `zfa_context.c`). Chosen with the user on 2026-10-03 over NG_GL4ES. The instance "Project Zomboid" runs at render scale 0.6, so with the wide canvas the game window is 1896x648 (world region 1152x648), not 3160x1080.

## Key code locations

- `GameActivity.java`: sets up `binding.gameSv` (a `GameInputView`, the game surface) and `binding.inputControlsV` (touch controls overlay). Surface handed to native via `GameLauncher.setSurface(surface, w, h)`. Layout is `res/layout/activity_game.xml`.
- `GameLauncher.java`: environment variables per renderer, JVM args, and the ZombieBuddy `-javaagent` hookup (enabled per instance by the `zombiebuddy_enabled_<instance>` shared pref).
- `input/InputControlsView.java`, `input/TouchpadControlElement.java`: touch controls. The touchpad clamps the cursor to its parent view's size; fix this if controls ever move to a different display.
- `input/InputNativeInterface.java`: Java-to-native input (`sendCursorPos` and friends).
- `cpp/zomdroid_jni.c`, `cpp/zomdroid.c`: JNI glue on the app side.

## Build

Requirements: JDK 17, Android SDK 35, NDK `27.3.13750724`, CMake `3.22.1`. Clone with `--recursive` (Box64 and GLFW are submodules).

```
./gradlew assembleDebug
```

Output: `app/build/outputs/apk/debug/zomdroid-debug-<version>.apk`.

### Separate app ID (do this first)

Upstream uses `applicationId = "com.zomdroid"` for both release and debug. Our `debug` build type adds `applicationIdSuffix = ".ds"`, so the debug app is `com.zomdroid.ds` (label "Zomdroid DS", from `app/src/debug/res/values/strings.xml`) and can sit next to a release Zomdroid. The provider authorities (`AppStorageProvider`, `FileProvider`) and the mod-install path in `InstallerService` derive from the app ID instead of hardcoding `com.zomdroid`. Java package names stay `com.zomdroid`. Don't reintroduce a hardcoded `com.zomdroid` package string.

The user installs B42 into `com.zomdroid.ds` once through the launcher.

## Install, launch, observe

Helper scripts live in `tools/ds/` (run with Git Bash; settings in `env.sh`):

| Script | Does |
|---|---|
| `build.sh` | `./gradlew assembleDebug` with JDK 17 |
| `install.sh` | `adb install -r` the newest debug APK (never uninstalls) |
| `launch.sh [instance]` | force-stop, then start an instance via the debug-only `DebugLaunchActivity` (first installed instance if no name) |
| `logs.sh clear` / `logs.sh` | clear logcat / dump filtered logcat to `zomboidDS/logs/logcat.txt`, plus the app's `files/log.txt` and `lastlog.txt` |
| `console.sh` | copy each instance's `Zomboid/console.txt` to `zomboidDS/logs/` |
| `shots.sh [label]` | screenshot both screens to `zomboidDS/shots/<label>-top.png`, `-bottom.png` |
| `tap.sh top/bottom X Y` | tap a screen (held 150 ms; a plain `input tap` is shorter than a game frame and gets lost) |
| `build_mod.sh` | compile `mod/DieSurviving` with JDK 25 into `42/media/java/DieSurviving.jar` |
| `push_mod.sh` | copy `mod/DieSurviving` into the instance's `Zomboid/mods` |
| `pref.sh bool\|float NAME VALUE` | set a launcher shared pref (stops the app first), e.g. `dual_screen_enabled`, `inst:Project Zomboid:render_scale`, `inst:Project Zomboid:renderer` (string prefs: edit by hand) |

Raw equivalents:

```
adb install -r app/build/outputs/apk/debug/zomdroid-debug-*.apk
adb shell am start -n com.zomdroid.ds/com.zomdroid.DebugLaunchActivity --es instance <name>
```

Logs (clear first, then filter):

```
adb logcat -c
adb logcat -v time | grep -iE "zomdroid|glfw|zombiebuddy|DieSurviving|AndroidRuntime|DEBUG"
```

Game-side Java and Lua output also lands in `files/instances/<name>/Zomboid/console.txt` inside the app's data dir. Because the debug build is debuggable, read it with:

```
adb shell run-as com.zomdroid.ds cat files/instances/<name>/Zomboid/console.txt
```

Screenshots of each screen (use the physical IDs recorded above):

```
adb exec-out screencap -p -d <top-physical-id>    > shots/top.png
adb exec-out screencap -p -d <bottom-physical-id> > shots/bottom.png
```

Look at both images after every test. A test isn't done until you've seen the bottom screen.

Input without touching the device: `adb shell input -d <display-id> tap X Y`.

## Game code reference

The Javadocs (https://demiurgequantified.github.io/ProjectZomboidJavaDocs/) and Lua docs (https://demiurgequantified.github.io/ProjectZomboidLuaDocs/) list signatures only. For real behavior, decompile the game's classes locally:

1. Pull the B42 game jar/classes from the instance's game folder with `run-as`, or copy them from the user's PC install if they have one.
2. Decompile with Vineflower into `../zomboidDS/reference/decompiled/` (outside this repo). The Linux depot in `../zomboidDS/support/depots` already has the B42 classes.
3. Grep there before writing any ZombieBuddy patch. Check how `UIManager` sets up its ortho projection, how `Core` reports screen size, how mouse position is clamped, and which `IsoCamera` methods the world renderer actually calls.

Decompiled game code never gets committed or pushed.

## Mod packaging

The mod lives in `mod/DieSurviving` (`42/mod.info`, `common/`, Java sources in `java/src`). It is built with plain `javac`/`jar` from `tools/ds/build_mod.sh` against the game jar from `../zomboidDS/support/depots/...` and the ZombieBuddy jar built from `../zomboidDS/support/ZombieBuddy-master` (JDK 25 and Gradle 9.3.1 live in `../zomboidDS/tools`). The built jar is gitignored.

ZombieBuddy 3.0.0-beta1 is installed on the instance from `../zomboidDS/tools/ZombieBuddy-3.0.0-beta1.zip` (built from that source, Workshop layout) through the launcher's Optimization screen. Both mods are enabled in `Zomboid/mods/default.txt` and in the save's `mods.txt` (originals kept as `*.bak-ds`).

- ZombieBuddy mod structure follows https://github.com/zed-0xff/ZBHelloWorld (`mod.info` with `require=\ZombieBuddy`, `javaJarFile=...`, `@Patch` classes discovered from `javaPkgName`).
- Build the mod's Java jar against the game classes as `compileOnly`.
- Push the mod into the instance's `mods` folder with `adb push` to `/data/local/tmp` and then `run-as ... cp`. Script this as `tools/ds/push_mod.sh` once it works.
- ZombieBuddy must be installed and enabled for the instance (Zomdroid has an installer for it).

## Milestones

**Guiding principle (from the user, 2026-10-03): play it like a real DS game.** The top screen is the world, driven by the gamepad; the bottom screen is the touch menus. Minimise switching between touching one screen and the other: anything the player reaches for with touch belongs on the bottom screen, and anything that comes up while playing with the gamepad stays on the top and is fully usable with the gamepad.

Bottom-screen debug switch: `adb shell setprop debug.zomdroid.ds.bottom split|solid|off` (read when the bottom surface is created, so relaunch after changing it). The native side logs `<fps> fps, bottom screen <ms> ms/frame on render thread` every 10 s under the `ZomdroidDS` tag. Disable dual-screen entirely with the shared pref `dual_screen_enabled=false` (`BottomScreen.PREF_ENABLED`).

0. **Plumbing.** Separate debug app ID; debug auto-launch; record display IDs and the primary renderer in this file; scripts for build, install, logs, screenshots, mod push.
   - Done (2026-10-03): `.ds` app ID, `DebugLaunchActivity` (verified launching "Project Zomboid"), display IDs, renderer (ZINK_ZFA), `tools/ds/` scripts. Left: `push_mod.sh` (comes with the mod).
1. **Proof of concept.** Any image on the bottom screen from the native layer — a solid color, then a mirrored strip of the game frame.
   - Done (2026-10-03) on ZFA: `dualscreen/BottomScreen.java` (Presentation + SurfaceView on display 4, `FLAG_NOT_FOCUSABLE`), `GameLauncher.setBottomSurface`, `g_zomdroid_bottom_surface`, `zomdroid_dualscreen.c`. Solid and mirror both verified by screenshot. Main menu: 60 fps with mirror on or off; 0.4-0.9 ms/frame on the render thread. Not yet checked: in-game FPS, gamepad focus with the Presentation up, turning the bottom screen off mid-game. An untested EGL (NG_GL4ES) version of the bottom present lives in `../zomboidDS/notes/egl-bottom-screen-untested.patch` for milestone 6.
2. **Wide canvas.** Game sees the side-by-side size; left region on top screen, right strip on bottom screen, at playable FPS.
   - Done (2026-10-03). Main menu at 3160-wide canvas: right-anchored menu buttons land on the bottom screen, ~60 fps, 0.5-0.8 ms/frame on the render thread. Milestone 1 in-game test (mirror mode, user's session): 49-60 fps, ~0.5 ms/frame; gamepad still controls the game with the Presentation up.
3. **World on top only.** ZombieBuddy patch confines the camera to the left region; the right strip is clear for UI.
   - Done (2026-10-03). Launcher passes `-Dzomdroid.ds.worldFraction=<top width / canvas width>`; DieSurviving patches `IsoCamera.getScreenWidth`, `Core.getOffscreenWidth`, and makes `Core.getScreenWidth` report the world width only inside `Core.DoStartFrameStuffInternal` / `DoStartFrameNoZoom` for a player (thread-local flag, since PZ queues draw commands on one thread and runs them on another). In game: world viewport 1152x648 on a 1896x648 canvas, right strip has no world, UI anchored to the right edge (speed controls, clock) lands on the bottom screen. 58-60 fps.
4. **Bottom-screen input.** Touches on the bottom screen act as mouse input at the right canvas coordinates (x + top region width); dragging items in the inventory works.
   - Done (2026-10-03): `dualscreen/BottomTouchInput`. Tap = left click (held 50 ms so the game's per-frame sampling sees it); drag past the touch slop = left button held from the touch-down point; long press = right click (context menu); two-finger vertical swipe = mouse wheel. The left button is only pressed once the gesture is known, so a long press never clicks first. Verified on device: buttons through character creation, long press opens item context menus, dragging an item from the inventory to the Ground pane moves it. Two-finger scroll is untested (adb can't inject multi-touch); needs a real finger.
   - The gesture pill on the bottom screen is the Thor's own navigation hint; it shows on the top screen too, even in immersive mode, so it isn't ours to hide. Making the bottom window focusable so it could hide its bars was tried and reverted: it moves key focus to the bottom display whenever it's touched.
5. **Menus on the bottom by default.** Lua layout manager (places windows in the right strip)
   - Started (2026-10-03): `42/media/lua/client/DieSurviving/DS_Inventory.lua` puts player 0's inventory and loot windows side by side in the bottom strip, pinned open (vanilla mouse mode collapses them to a hover-to-open title bar). Java exposes `DieSurviving_worldWidth(canvasWidth)` to Lua (`LuaApi`, ZombieBuddy `@LuaMethod` global). with the exclusion list; decide how context menus behave.
   - Done (2026-10-03), all in `42/media/lua/client/DieSurviving/`:
     - `DS_Layout.lua`: shared geometry (`DS.strip()`, `DS.windowArea()` below the HUD rows and the clock/speed-controls corner column, `DS.placeInWindowArea()`).
     - `DS_HUD.lua`: the `ISEquippedItem` sidebar becomes rows across the top of the bottom screen, wrapping before the corner column (clock + speed controls stay in the bottom screen's top-right). Its `setX/setY` are pinned because `ISPlayerDataObject` repositions it. Debug/ARF buttons (debug mode only) wrap to a second row at render scale 0.6.
     - `DS_Windows.lua`: every UI frame (`OnPreUIDraw`), top-level windows/dialogs (`ISCollapsableWindow(Joypad)`, `ISModalDialog`, `ISModalRichText`, `ISTextBox`) that show in the world area move into the window area; context menus, tooltips, HUD, inventory pages, radial menus excluded. A window the player drags onto the top screen stays there. Windows too wide for the strip are right-aligned once (the game clamps them to the canvas), e.g. the Survival Guide.
     - `DS_Inventory.lua`: inventory and loot side by side in the window area, re-placed when the HUD rows change height.
     - `DS_Map.lua`: the world map fills the bottom screen; world drawing stays on so the top screen keeps showing the world.
     - `DS_Background.lua`: black backdrop behind all bottom-screen UI; nothing else clears that part of the canvas, so without it old pixels linger.
     - Verified: HUD buttons open crafting, character info and the map on the bottom screen; top screen shows only the world.
     - **Scale decision (user, 2026-10-03): stay at render scale 0.5-0.6** (higher makes the Thor's small screens harder to read). The bottom strip is then ~744x648 canvas px, below PZ's minimum UI size, so big windows (Survival Guide, crafting, ...) get reflowed for the strip one by one.
     - HUD band moved to the **bottom** edge of the bottom screen (user: the top edge next to the hinge is hard to reach); `DS.HUD_AT_BOTTOM` in `DS_Layout.lua`, to become a mod option. Clock + speed controls are re-placed every frame into the band's right corner (the game re-anchors them in `UIManager.resize`).
     - Left stick in context menus also freezes character movement (`setIgnoreInputsForDirection`) while the menu has focus.
     - Things centred on the screen that mean the top screen run in a "world scope" (`DualScreen.enterWorldScope()`; `Core.getScreenWidth()` reports the world width there): player viewports, `GameLoadingState`/`TISLogoState`/`ServerDisconnectState.render`, the "Game Paused" banner in `UIManager.render`, the startup epilepsy warning. Still to do: the main menu (Scenarios bar spills onto the bottom screen), moodles (anchored to the canvas's right edge), tutorial popups, debug views. Found by grepping decompiled code for `getScreenWidth() / 2`.
   - Roadmap (user, 2026-10-03):
     - Move the left-side HUD icon column (inventory, health, crafting, and so on: `ISEquippedItem`) to a horizontal row along the top of the bottom screen. Bottom-screen menus get a little less vertical space to make room for it.
     - World context menus (right click / Y on something in the world) stay on the top screen, and must be navigable with the left stick as well as the d-pad, submenus included.
       - Implemented (2026-10-03, `DS_ContextStick.lua`): while a context menu has a player's joypad focus, the left stick sends the same `onJoypadDir*` steps as the d-pad (push = one step, held = repeat after 300 ms, every 120 ms). Untested on device: adb can't inject stick axes, needs the user.
6. **Polish.**
   - Home/recents: `GameActivity.onStart/onStop` show and hide the bottom screen, so it leaves with the game (2026-10-03; leaving verified, returning not yet).
   - Chunk-texture seams (black horizontal lines in the world; see Gotchas): dig into `FBORenderChunk` stitching and patch it. In-launcher toggle for dual-screen mode; graceful fallback to normal mode when no secondary display exists or it's turned off; the other renderer paths.

Update this list as milestones land, and add notes on anything learned the hard way to "Gotchas" below.

## Rules

- **Never uninstall `com.zomdroid` or `com.zomdroid.ds`**, and never `pm clear` either. Both hold a multi-gigabyte game install and saves. If you think an uninstall is needed, stop and ask.
- Never delete files in the game folder or saves. Back up before editing configs on device.
- Native changes go in the `zomdroid-glfw` fork. Commit and push there, then commit the updated submodule pointer here. Never leave the submodule on an unpushed commit.
- Keep upstream mergeable: put dual-screen code behind a setting or a clear code path, and avoid reformatting files you don't otherwise change.
- Don't commit APKs, screenshots, logs, or decompiled code.

## Gotchas

- The Thor's bottom screen being secondary means `Presentation` windows on it can be dismissed by the system if the display turns off (the user can long-press the button under the bottom screen to turn it off). Handle display removal without crashing.
- Running both screens costs some performance; measure FPS with the bottom screen on and off.
- `GameActivity` is locked to `sensorLandscape` with `configChanges` set so the GL surface isn't torn down on rotation. Keep it that way.
- The app's `CrashHandler` runs `logcat -c` when the process starts. That wipes the app's own earliest log lines from logcat, so `Application`/first-activity logs usually never show up there. The app streams its logcat into `files/log.txt`; the previous session is in `files/lastlog.txt`. `tools/ds/logs.sh` pulls both. Read those, not just logcat.
- `local.properties` needs forward slashes (`sdk.dir=C:/Users/...`). Single backslashes are read as escapes, which breaks NDK lookup with "filename, directory name, or volume label syntax is incorrect".
- The instance's renderer is per-instance (`inst:<name>:renderer` in `shared_prefs`), and overrides the launcher-wide one. Check the `Renderer:` line in `files/log.txt` instead of assuming.
- `ANativeWindow_lock` on the bottom window blocks until the bottom display releases a buffer (up to a 60 Hz vsync, measured at 13-15 ms/frame). Never lock it on the render thread; `zomdroid_dualscreen.c` does it on its own worker thread.
- `glReadPixels` reports `GL_INVALID_OPERATION` (0x501) once during startup on ZFA, then never again. Harmless so far; probably the first frames before the real window is attached.
- The gesture-navigation pill shows on the bottom screen over the Presentation. Hide it when the bottom screen starts taking input (milestone 4).
- ZombieBuddy only applies `@Patch` classes declared **directly** in `javaPkgName`, not in subpackages ("no patches to apply" in the log otherwise).
- Git Bash rewrites `/device/paths` passed to `adb.exe` into Windows paths (`C:/Program Files/Git/...`), silently. `tools/ds/env.sh` exports `MSYS_NO_PATHCONV=1`; local paths handed to `adb` then need `cygpath -w`, and `build_mod.sh` unsets it again because `javac` needs the translation.
- The game classes are Java 25 class files: compiling against them needs JDK 25, not the JDK 17 used for the app.
- "Continue" on the main menu goes to spawn selection when the save's character is dead (`players.db` → `localPlayers.isDead`). That is the game, not us.
- The game runs in debug mode on this instance (Output Log / Lua console on screen); that is a Zomdroid setting, not ours.
- **Black horizontal lines in the world (top screen) are not ours.** A/B tested on 2026-10-03 at the same spot: present with dual-screen off (stock layout, mod inert), at render scale 0.6 and 1.0, with `FBORenderChunk.HighResChunkTextures=true` or `DepthTestAll=false` in `debug-options.ini`, and on NG_GL4ES as well as Zink. Gone only with B42's chunk-texture renderer off (`PerformanceSettings.fboRenderChunk=false`, the debug "toggle old renderer"), which draws some things differently (string lights unlit, different wall cutaways). The lines move with the world, so they're seams in the chunk textures. To repeat the test: create an empty `ds-old-renderer` file in the instance home (`files/instances/<name>/`); DieSurviving's `Main` then turns the chunk renderer off at load.
- `ISUIElement:setX/setY` clamp windows to the canvas using the window's **current** size (`keepOnScreen`). Set width/height before x/y, or a shrinking window gets stuck at its old position.
- The bottom strip is not cleared by the game between frames (world clears only its viewport); `DS_Background.lua` paints it black behind the UI.
- **ZombieBuddy inlines advice code into the target class.** Any field or method the advice touches must be `public`, or the game dies with `IllegalAccessError: class zombie.X tried to access field ...` the first time the patched method runs (this crashed the game right after the epilepsy warning once).
