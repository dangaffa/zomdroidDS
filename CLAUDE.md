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

## Architecture: the tall virtual canvas

The game only knows one window. We tell it that window is both screens stacked, then split the output.

1. **Native layer** (`app/src/main/cpp/glfw`, a submodule pointing at our fork of `zomdroid-glfw`). The game renders into an offscreen framebuffer sized roughly 1920x2160. At each buffer swap we copy the top 1920x1080 region to the top display's surface and the bottom region (1240x1080) to a second surface on the bottom display. The second `ANativeWindow` comes from the Android side.
2. **Android layer** (`app/src/main/java/com/zomdroid`). `GameActivity` finds the secondary display via `DisplayManager`, shows a `android.app.Presentation` on it containing a `SurfaceView`, and hands that surface to native code alongside the existing one. Touches on the bottom screen become mouse input with y offset by 1080 (or whatever the top region's height is).
3. **Java mod via ZombieBuddy** (`mod/DieSurviving/.../media/java`). ByteBuddy `@Patch` classes that restrict player 0's camera (`zombie.iso.IsoCamera` screen/offscreen region methods) to the top region, fix the UI projection to cover the full canvas, and stop the mouse from being clamped to the top region.
4. **Lua mod** (`mod/DieSurviving/.../media/lua`). Catches windows as they're created (`ISCollapsableWindow`, `ISPanel`, and so on, hooked at `addToUIManager` or construction) and places them in the bottom region by default. Keeps an exclusion list for things that must stay on top: HUD, tooltips, on-world overlays, the main menu. Context menus (`ISContextMenu`) are an open design question; decide during testing.

### Renderer paths

The GLFW fork has three separate present paths, all of which need the split eventually:

- `src/egl_context.c`: EGL (GL4ES renderers). Swap is in `swapBuffersEGL`; surface recreation uses `g_zomdroid_surface`.
- `src/zfa_context.c`: ZFA (Zink, ZINK_ZFA).
- `src/osmesa_context.c`: OSMesa (Zink, ZINK_OSMESA). Software buffer locked via `ANativeWindow_lock`, so the bottom copy is a plain memory copy.

**Pick one renderer first** (whichever runs B42 best on the Thor — check with the user) and get it fully working before touching the others. Record the choice here:

- Primary renderer: `NG_GL4ES` (upstream's supported B42 route; EGL path in `egl_context.c`)

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
| `tap.sh top/bottom X Y` | tap a screen |

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

- ZombieBuddy mod structure follows https://github.com/zed-0xff/ZBHelloWorld (`mod.info` with `require=\ZombieBuddy`, `javaJarFile=...`, `@Patch` classes discovered from `javaPkgName`).
- Build the mod's Java jar against the game classes as `compileOnly`.
- Push the mod into the instance's `mods` folder with `adb push` to `/data/local/tmp` and then `run-as ... cp`. Script this as `tools/ds/push_mod.sh` once it works.
- ZombieBuddy must be installed and enabled for the instance (Zomdroid has an installer for it).

## Milestones

0. **Plumbing.** Separate debug app ID; debug auto-launch; record display IDs and the primary renderer in this file; scripts for build, install, logs, screenshots, mod push.
   - Done (2026-10-03): `.ds` app ID, `DebugLaunchActivity`, display IDs, renderer (NG_GL4ES), `tools/ds/` scripts. Left: `push_mod.sh` (comes with the mod); checking that `DebugLaunchActivity` launches a real instance once B42 is installed into `com.zomdroid.ds`.
1. **Proof of concept.** Any image on the bottom screen from the native layer — a solid color, then a mirrored strip of the game frame.
2. **Tall canvas.** Game sees the stacked size; top region on top screen, bottom region on bottom screen, at playable FPS.
3. **World on top only.** ZombieBuddy patch confines the camera to the top region; bottom region is clear for UI.
4. **Bottom-screen input.** Touches on the bottom screen act as mouse input at the right canvas coordinates; dragging items in the inventory works.
5. **Menus on the bottom by default.** Lua layout manager with the exclusion list; decide how context menus behave.
6. **Polish.** In-launcher toggle for dual-screen mode; graceful fallback to normal mode when no secondary display exists or it's turned off; the other renderer paths.

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
