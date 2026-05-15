#!/usr/bin/env bash
set -euo pipefail
shopt -s nullglob

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
NEWBLACKBOX_DIR="$ROOT_DIR/NewBlackbox"
LOADER_AAR="$ROOT_DIR/app/libs/Bcore-release.aar"
ARTIFACTS_DIR="${ARTIFACTS_DIR:-$ROOT_DIR/build/newblackbox-loader-artifacts}"
SDK_DIR="${SDK_DIR:-}"
BCORE_VARIANT="${BCORE_VARIANT:-release}"
LOADER_VARIANT="${LOADER_VARIANT:-release}"
ALLOW_DEBUG_FALLBACK="${ALLOW_DEBUG_FALLBACK:-false}"
FORCE_GENERATED_SIGNING="${FORCE_GENERATED_SIGNING:-false}"
ROOT_LOCAL_PROPERTIES="$ROOT_DIR/local.properties"
NEWBLACKBOX_LOCAL_PROPERTIES="$NEWBLACKBOX_DIR/local.properties"
SIGNING_PROPERTIES="$ROOT_DIR/signing.properties"
ROOT_LOCAL_BACKUP=""
NEWBLACKBOX_LOCAL_BACKUP=""
SIGNING_PROPERTIES_BACKUP=""
SIGNING_PROPERTIES_CREATED="false"
NEWBLACKBOX_AAR=""
LOADER_OUTPUT_DIR=""
GENERATED_SIGNING_DIR="$ROOT_DIR/build/generated-signing"

variant_capitalized() {
  local variant="$1"
  printf '%s%s' "${variant:0:1}" "${variant:1}" | awk '{print toupper(substr($0,1,1)) substr($0,2)}'
}

set_artifact_paths() {
  NEWBLACKBOX_AAR="$NEWBLACKBOX_DIR/Bcore/build/outputs/aar/Bcore-${BCORE_VARIANT}.aar"
  LOADER_OUTPUT_DIR="$ROOT_DIR/app/build/outputs/apk/${LOADER_VARIANT}"
}

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

  if [[ -n "$SIGNING_PROPERTIES_BACKUP" ]]; then
    cp "$SIGNING_PROPERTIES_BACKUP" "$SIGNING_PROPERTIES"
    rm -f "$SIGNING_PROPERTIES_BACKUP"
  elif [[ "$SIGNING_PROPERTIES_CREATED" == "true" ]]; then
    rm -f "$SIGNING_PROPERTIES"
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
  elif [[ -x ./gradlew ]]; then
    ./gradlew "$@"
  else
    bash ./gradlew "$@"
  fi
}

build_bcore() {
  local task=":Bcore:assemble$(variant_capitalized "$BCORE_VARIANT")"
  echo "==> Building NewBlackbox Bcore ${BCORE_VARIANT} AAR"

  if run_gradle "$NEWBLACKBOX_DIR" "$task" --configure-on-demand --stacktrace --no-daemon; then
    return
  fi

  if [[ "$ALLOW_DEBUG_FALLBACK" == "true" && "$BCORE_VARIANT" != "debug" ]]; then
    echo "Release Bcore build failed; retrying debug because ALLOW_DEBUG_FALLBACK=true."
    BCORE_VARIANT="debug"
    set_artifact_paths
    run_gradle "$NEWBLACKBOX_DIR" :Bcore:assembleDebug --configure-on-demand --stacktrace --no-daemon
    return
  fi

  return 1
}

build_loader() {
  local task=":app:assemble$(variant_capitalized "$LOADER_VARIANT")"
  echo "==> Building Loader ${LOADER_VARIANT} APK"

  if run_gradle "$ROOT_DIR" "$task" --stacktrace --no-daemon; then
    return
  fi

  if [[ "$ALLOW_DEBUG_FALLBACK" == "true" && "$LOADER_VARIANT" != "debug" ]]; then
    echo "Release Loader build failed; retrying debug because ALLOW_DEBUG_FALLBACK=true."
    LOADER_VARIANT="debug"
    set_artifact_paths
    run_gradle "$ROOT_DIR" :app:assembleDebug --stacktrace --no-daemon
    return
  fi

  return 1
}

prepare_local_properties
set_artifact_paths

prepare_loader_signing() {
  # The loader build.gradle always assigns signingConfigs.release/debug.
  # GitHub Actions and fresh clones can therefore fail if no keystore is
  # available.  When signing values are not already supplied by the repo or
  # environment, create a disposable debug keystore so the APK can still be
  # produced and uploaded as a CI artifact.
  local configured_store=""

  if [[ "$FORCE_GENERATED_SIGNING" != "true" && -f "$SIGNING_PROPERTIES" ]]; then
    configured_store="$(sed -n 's/^storeFile=//p' "$SIGNING_PROPERTIES" | tail -n 1)"
    if [[ -n "$configured_store" && -f "$ROOT_DIR/$configured_store" ]]; then
      echo "Using existing Loader signing keystore: $configured_store"
      return
    fi
  fi

  mkdir -p "$GENERATED_SIGNING_DIR"
  export STORE_FILE="$GENERATED_SIGNING_DIR/debug-ci.jks"
  export STORE_PASSWORD="${STORE_PASSWORD:-android}"
  export KEY_ALIAS="${KEY_ALIAS:-androiddebugkey}"
  export KEY_PASSWORD="${KEY_PASSWORD:-android}"

  if [[ ! -f "$STORE_FILE" ]]; then
    keytool -genkeypair -v \
      -keystore "$STORE_FILE" \
      -storepass "$STORE_PASSWORD" \
      -keypass "$KEY_PASSWORD" \
      -alias "$KEY_ALIAS" \
      -keyalg RSA \
      -keysize 2048 \
      -validity 10000 \
      -dname "CN=Android Debug,O=Android,C=US"
  fi

  if [[ -z "$SIGNING_PROPERTIES_BACKUP" && -f "$SIGNING_PROPERTIES" ]]; then
    SIGNING_PROPERTIES_BACKUP="$(mktemp)"
    cp "$SIGNING_PROPERTIES" "$SIGNING_PROPERTIES_BACKUP"
  elif [[ ! -f "$SIGNING_PROPERTIES" ]]; then
    SIGNING_PROPERTIES_CREATED="true"
  fi

  cat > "$SIGNING_PROPERTIES" <<EOF
storeFile=$STORE_FILE
storePassword=$STORE_PASSWORD
keyAlias=$KEY_ALIAS
keyPassword=$KEY_PASSWORD
EOF

  echo "Generated disposable Loader signing keystore and temporary signing.properties for this build."
}

prepare_loader_signing

build_bcore

if [[ ! -f "$NEWBLACKBOX_AAR" ]]; then
  echo "Expected NewBlackbox AAR was not produced: $NEWBLACKBOX_AAR" >&2
  exit 1
fi

mkdir -p "$(dirname "$LOADER_AAR")" "$ARTIFACTS_DIR"
rm -f "$ARTIFACTS_DIR"/*
cp "$NEWBLACKBOX_AAR" "$LOADER_AAR"
cp "$NEWBLACKBOX_AAR" "$ARTIFACTS_DIR/NewBlackbox-Bcore-${BCORE_VARIANT}.aar"
echo "==> Replaced Loader AAR: $LOADER_AAR"

build_loader

apk_files=("$LOADER_OUTPUT_DIR"/*.apk)
if (( ${#apk_files[@]} == 0 )); then
  echo "Loader build completed, but no APK was found in: $LOADER_OUTPUT_DIR" >&2
  exit 1
fi

for apk in "${apk_files[@]}"; do
  cp "$apk" "$ARTIFACTS_DIR/Loader-${LOADER_VARIANT}-$(basename "$apk")"
done

cat <<MSG

Build complete.
AAR and Loader APK copied here:
$ARTIFACTS_DIR
MSG
