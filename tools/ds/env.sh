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
if [ -z "$JAVA_HOME" ] && [ -d "/c/Program Files/Java/jdk-17" ]; then
    export JAVA_HOME="C:/Program Files/Java/jdk-17"
fi
mkdir -p "$OUT_DIR/logs" "$OUT_DIR/shots"
