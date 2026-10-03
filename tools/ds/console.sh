#!/usr/bin/env bash
# Copy every instance's Zomboid/console.txt to OUT_DIR/logs/console-<instance>.txt
source "$(dirname "$0")/env.sh"
for f in $("$ADB" shell run-as "$PKG" sh -c "'ls files/instances/*/Zomboid/console.txt'" 2>/dev/null | tr -d '\r'); do
    name=$(echo "$f" | cut -d/ -f3)
    "$ADB" exec-out run-as "$PKG" cat "$f" > "$OUT_DIR/logs/console-$name.txt"
    echo "$OUT_DIR/logs/console-$name.txt"
done
