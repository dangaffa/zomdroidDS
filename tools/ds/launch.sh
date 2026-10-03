#!/usr/bin/env bash
# Start a game instance directly. Usage: launch.sh [instance-name]
set -e
source "$(dirname "$0")/env.sh"
"$ADB" shell am force-stop "$PKG"
if [ -n "$1" ]; then
    "$ADB" shell am start -n "$PKG/com.zomdroid.DebugLaunchActivity" --es instance "$1"
else
    "$ADB" shell am start -n "$PKG/com.zomdroid.DebugLaunchActivity"
fi
