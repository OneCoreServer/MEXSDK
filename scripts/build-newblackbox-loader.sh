#!/usr/bin/env bash
set -euo pipefail
shopt -s nullglob

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
NEWBLACKBOX_DIR="$ROOT_DIR/NewBlackbox"
NEWBLACKBOX_AAR="$NEWBLACKBOX_DIR/Bcore/build/outputs/aar/Bcore-release.aar"
LOADER_AAR="$ROOT_DIR/app/libs/Bcore-release.aar"
LOADER_RELEASE_DIR="$ROOT_DIR/app/build/outputs/apk/release"
ARTIFACTS_DIR="${ARTIFACTS_DIR:-$ROOT_DIR/build/newblackbox-loader-artifacts}"
SDK_DIR="${SDK_DIR:-}"
ROOT_LOCAL_PROPERTIES="$ROOT_DIR/local.properties"
NEWBLACKBOX_LOCAL_PROPERTIES="$NEWBLACKBOX_DIR/local.properties"
ROOT_LOCAL_BACKUP=""
NEWBLACKBOX_LOCAL_BACKUP=""

restore_local_properties() {
  if [[ -n "$ROOT_LOCAL_BACKUP" ]]; then
    cp "$ROOT_LOCAL_BACKUP" "$ROOT_LOCAL_PROPERTIES"
    rm -f "$ROOT_LOCAL_BACKUP"
  fi

  if [[ -n "$NEWBLACKBOX_LOCAL_BACKUP" ]]; then
    cp "$NEWBLACKBOX_LOCAL_BACKUP" "$NEWBLACKBOX_LOCAL_PROPERTIES"
    rm -f "$NEWBLACKBOX_LOCAL_BACKUP"
  elif [[ -n "$SDK_DIR" ]]; then
    rm -f "$NEWBLACKBOX_LOCAL_PROPERTIES"
  fi
}

trap restore_local_properties EXIT

if [[ ! -d "$NEWBLACKBOX_DIR" ]]; then
  echo "NewBlackbox project not found: $NEWBLACKBOX_DIR" >&2
  exit 1
fi

write_sdk_local_properties() {
  local sdk_dir_escaped="${SDK_DIR//\\/\\\\}"

  if [[ -f "$ROOT_LOCAL_PROPERTIES" ]]; then
    ROOT_LOCAL_BACKUP="$(mktemp)"
    cp "$ROOT_LOCAL_PROPERTIES" "$ROOT_LOCAL_BACKUP"
  fi

  if [[ -f "$NEWBLACKBOX_LOCAL_PROPERTIES" ]]; then
    NEWBLACKBOX_LOCAL_BACKUP="$(mktemp)"
    cp "$NEWBLACKBOX_LOCAL_PROPERTIES" "$NEWBLACKBOX_LOCAL_BACKUP"
  fi

  printf 'sdk.dir=%s\n' "$sdk_dir_escaped" > "$ROOT_LOCAL_PROPERTIES"
  printf 'sdk.dir=%s\n' "$sdk_dir_escaped" > "$NEWBLACKBOX_LOCAL_PROPERTIES"
  export ANDROID_HOME="$SDK_DIR"
  export ANDROID_SDK_ROOT="$SDK_DIR"
  echo "Using SDK_DIR for both Loader and NewBlackbox: $SDK_DIR"
}

prepare_local_properties() {
  # SDK_DIR=/path/to/Android/Sdk is the safest way to build because this repo
  # contains a checked-in local.properties file that may point to another PC.
  if [[ -n "$SDK_DIR" ]]; then
    if [[ ! -d "$SDK_DIR" ]]; then
      echo "SDK_DIR does not exist: $SDK_DIR" >&2
      exit 1
    fi
    write_sdk_local_properties
    return
  fi

  # NewBlackbox is a standalone Gradle build, so it needs its own SDK config.
  # If the caller did not set ANDROID_HOME/ANDROID_SDK_ROOT and NewBlackbox has
  # no local.properties, reuse the Loader project's sdk.dir automatically.
  if [[ -z "${ANDROID_HOME:-}" && -z "${ANDROID_SDK_ROOT:-}" \
      && ! -f "$NEWBLACKBOX_LOCAL_PROPERTIES" && -f "$ROOT_LOCAL_PROPERTIES" ]]; then
    cp "$ROOT_LOCAL_PROPERTIES" "$NEWBLACKBOX_LOCAL_PROPERTIES"
    echo "Copied Loader local.properties to NewBlackbox/local.properties for SDK lookup."
  fi
}

run_gradle() {
  local project_dir="$1"
  shift

  cd "$project_dir"

  if [[ -n "${GRADLE_CMD:-}" ]]; then
    "$GRADLE_CMD" "$@"
  elif command -v gradle >/dev/null 2>&1; then
    gradle "$@"
  elif [[ -x ./gradlew ]]; then
    ./gradlew "$@"
  else
    bash ./gradlew "$@"
  fi
}

prepare_local_properties

echo "==> Building NewBlackbox Bcore release AAR"
run_gradle "$NEWBLACKBOX_DIR" :Bcore:assembleRelease --no-daemon

if [[ ! -f "$NEWBLACKBOX_AAR" ]]; then
  echo "Expected NewBlackbox AAR was not produced: $NEWBLACKBOX_AAR" >&2
  exit 1
fi

mkdir -p "$(dirname "$LOADER_AAR")" "$ARTIFACTS_DIR"
cp "$NEWBLACKBOX_AAR" "$LOADER_AAR"
cp "$NEWBLACKBOX_AAR" "$ARTIFACTS_DIR/NewBlackbox-Bcore-release.aar"
echo "==> Replaced Loader AAR: $LOADER_AAR"

echo "==> Building Loader release APK"
run_gradle "$ROOT_DIR" :app:assembleRelease --no-daemon

apk_files=("$LOADER_RELEASE_DIR"/*.apk)
if (( ${#apk_files[@]} == 0 )); then
  echo "Loader build completed, but no APK was found in: $LOADER_RELEASE_DIR" >&2
  exit 1
fi

for apk in "${apk_files[@]}"; do
  cp "$apk" "$ARTIFACTS_DIR/Loader-$(basename "$apk")"
done

cat <<MSG

Build complete.
AAR and Loader APK copied here:
$ARTIFACTS_DIR
MSG
