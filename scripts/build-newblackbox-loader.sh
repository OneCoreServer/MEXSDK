#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
NEWBLACKBOX_DIR="$ROOT_DIR/NewBlackbox"
NEWBLACKBOX_AAR="$NEWBLACKBOX_DIR/Bcore/build/outputs/aar/Bcore-release.aar"
LOADER_AAR="$ROOT_DIR/app/libs/Bcore-release.aar"

if [[ -z "${ANDROID_HOME:-}" && -z "${ANDROID_SDK_ROOT:-}" ]]; then
  cat >&2 <<'MSG'
Android SDK location is not configured.
Set ANDROID_HOME or ANDROID_SDK_ROOT, or add a valid sdk.dir to local.properties.
MSG
  exit 1
fi

if [[ ! -d "$NEWBLACKBOX_DIR" ]]; then
  echo "NewBlackbox project not found: $NEWBLACKBOX_DIR" >&2
  exit 1
fi

cd "$NEWBLACKBOX_DIR"
./gradlew :Bcore:assembleRelease --no-daemon

if [[ ! -f "$NEWBLACKBOX_AAR" ]]; then
  echo "Expected NewBlackbox AAR was not produced: $NEWBLACKBOX_AAR" >&2
  exit 1
fi

cp "$NEWBLACKBOX_AAR" "$LOADER_AAR"

cd "$ROOT_DIR"
./gradlew :app:assembleRelease --no-daemon

echo "Updated Loader AAR: $LOADER_AAR"
echo "Loader release APK output directory: $ROOT_DIR/app/build/outputs/apk/release"
