#!/usr/bin/env bash
# Tap a screen. Usage: tap.sh top|bottom X Y
source "$(dirname "$0")/env.sh"
case "$1" in top) d=$TOP_DISPLAY ;; bottom) d=$BOTTOM_DISPLAY ;; *) echo "top|bottom"; exit 1 ;; esac
"$ADB" shell input -d "$d" tap "$2" "$3"
