# Shared settings for the dual-screen helper scripts. Source this, don't run it.
DS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$DS_DIR/../.." && pwd)"
# Logs and screenshots go outside the repo so they never get committed.
OUT_DIR="${DS_OUT_DIR:-$REPO_DIR/../zomboidDS}"
PKG=com.zomdroid.ds
TOP_DISPLAY=0
BOTTOM_DISPLAY=4
TOP_PHYS=4630946441858561667
BOTTOM_PHYS=4630946482288158084
ADB="${ADB:-adb}"
# Git Bash rewrites /device/paths into Windows paths for adb.exe; keep them as written.
export MSYS_NO_PATHCONV=1
if [ -z "$JAVA_HOME" ] && [ -d "/c/Program Files/Java/jdk-17" ]; then
    export JAVA_HOME="C:/Program Files/Java/jdk-17"
fi
mkdir -p "$OUT_DIR/logs" "$OUT_DIR/shots"
# Mod build: JDK 25 (game classes are Java 25), the game jar and ZombieBuddy.jar to compile against.
JDK25="${JDK25:-$(ls -d "$OUT_DIR"/tools/jdk-25* 2>/dev/null | head -1)}"
GAME_JAR="${GAME_JAR:-$OUT_DIR/support/depots/108603/25485521/projectzomboid/projectzomboid.jar}"
ZB_JAR="${ZB_JAR:-$OUT_DIR/support/ZombieBuddy-master/ZombieBuddy-master/java/build/jdk25/libs/ZombieBuddy-master.jar}"
INSTANCE="${INSTANCE:-Project Zomboid}"
