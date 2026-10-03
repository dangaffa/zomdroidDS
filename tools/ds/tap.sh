#!/usr/bin/env bash
# Tap a screen. Usage: tap.sh top|bottom X Y
source "$(dirname "$0")/env.sh"
case "$1" in top) d=$TOP_DISPLAY ;; bottom) d=$BOTTOM_DISPLAY ;; *) echo "top|bottom"; exit 1 ;; esac
# A plain tap is shorter than a game frame and gets lost; hold it for 150 ms.
"$ADB" shell input -d "$d" swipe "$2" "$3" "$2" "$3" 150
