#!/usr/bin/env bash
# logs.sh clear -> clear logcat
# logs.sh       -> dump filtered logcat to OUT_DIR/logs/logcat.txt, plus the app's own log files.
# The app's CrashHandler runs `logcat -c` at startup (which drops the app's earliest lines from
# logcat) and streams its logs into files/log.txt; the previous session is files/lastlog.txt.
source "$(dirname "$0")/env.sh"
if [ "$1" = clear ]; then "$ADB" logcat -c; exit; fi
out="$OUT_DIR/logs/logcat.txt"
"$ADB" logcat -d -v time > "$OUT_DIR/logs/logcat-full.txt"
grep -iE "zomdroid|glfw|zombiebuddy|DieSurviving|DebugLaunch|AndroidRuntime|DEBUG|FATAL|libc" \
    "$OUT_DIR/logs/logcat-full.txt" > "$out"
"$ADB" exec-out run-as "$PKG" cat files/log.txt > "$OUT_DIR/logs/app-log.txt" 2>/dev/null
"$ADB" exec-out run-as "$PKG" cat files/lastlog.txt > "$OUT_DIR/logs/app-lastlog.txt" 2>/dev/null
echo "$out ($(wc -l < "$out") lines), logcat-full.txt, app-log.txt, app-lastlog.txt"
