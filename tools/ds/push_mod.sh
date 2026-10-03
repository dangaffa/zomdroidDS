#!/usr/bin/env bash
# Copy mod/DieSurviving into the instance's Zomboid/mods folder on the device.
set -e
source "$(dirname "$0")/env.sh"
MOD="$REPO_DIR/mod/DieSurviving"
DEST="files/instances/$INSTANCE/Zomboid/mods/DieSurviving"
TMP=/data/local/tmp/DieSurviving
"$ADB" shell rm -rf "$TMP"
"$ADB" push "$(cygpath -w "$MOD/42")" "$TMP/42" >/dev/null
"$ADB" push "$(cygpath -w "$MOD/common")" "$TMP/common" >/dev/null
"$ADB" shell "run-as $PKG sh -c \"rm -rf '$DEST' && mkdir -p '$DEST' && cp -r $TMP/42 $TMP/common '$DEST'/ && rm -f '$DEST/common/.keep'\""
"$ADB" shell rm -rf "$TMP"
echo "pushed to $DEST"
"$ADB" shell "run-as $PKG find '$DEST' -type f"
