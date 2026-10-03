#!/usr/bin/env bash
# Screenshot both screens. Usage: shots.sh [label]  -> OUT_DIR/shots/<label>-top.png, -bottom.png
source "$(dirname "$0")/env.sh"
label="${1:-latest}"
"$ADB" exec-out screencap -p -d "$TOP_PHYS" > "$OUT_DIR/shots/$label-top.png"
"$ADB" exec-out screencap -p -d "$BOTTOM_PHYS" > "$OUT_DIR/shots/$label-bottom.png"
ls -l "$OUT_DIR/shots/$label-top.png" "$OUT_DIR/shots/$label-bottom.png"
