#!/usr/bin/env bash
# Install the newest debug APK over the existing com.zomdroid.ds. Never uninstalls.
set -e
source "$(dirname "$0")/env.sh"
apk=$(ls -t "$REPO_DIR"/app/build/outputs/apk/debug/*.apk | head -1)
echo "Installing $apk"
"$ADB" install -r "$(cygpath -w "$apk")"
