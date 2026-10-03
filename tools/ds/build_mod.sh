#!/usr/bin/env bash
# Compile the DieSurviving Java mod into mod/DieSurviving/42/media/java/DieSurviving.jar.
set -e
source "$(dirname "$0")/env.sh"
# Only local tools here: let Git Bash translate paths for javac/jar again.
unset MSYS_NO_PATHCONV
MOD="$REPO_DIR/mod/DieSurviving"
OUT="$MOD/java/build"
rm -rf "$OUT" && mkdir -p "$OUT/classes"
SRCS=$(find "$MOD/java/src" -name "*.java")
"$JDK25/bin/javac" -nowarn --release 25 -cp "$(cygpath -w "$GAME_JAR");$(cygpath -w "$ZB_JAR")" -d "$OUT/classes" $SRCS
"$JDK25/bin/jar" --create --file "$MOD/42/media/java/DieSurviving.jar" -C "$OUT/classes" .
echo "built $MOD/42/media/java/DieSurviving.jar"
