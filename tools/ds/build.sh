#!/usr/bin/env bash
# Build the debug APK (com.zomdroid.ds).
set -e
source "$(dirname "$0")/env.sh"
cd "$REPO_DIR"
./gradlew assembleDebug --console=plain "$@"
