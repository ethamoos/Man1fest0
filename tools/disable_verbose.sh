#!/usr/bin/env bash
# Disable verbose logging for Man1fest0
# Usage: disable_verbose.sh <bundle-id | path-to-app.app> [--remove-defaults] [--dry-run]

set -euo pipefail

usage() {
  cat <<EOF
Usage: $0 <bundle-id | path-to-app.app> [--remove-defaults] [--dry-run]

Examples:
  $0 com.example.Man1fest0         # remove flag file and remove UserDefaults key
  $0 /Applications/Man1fest0.app    # read bundle id from app and disable
  $0 com.example.Man1fest0 --dry-run
  $0 com.example.Man1fest0 --no-remove-defaults

Options:
  --remove-defaults   : remove the UserDefaults key Man1fest0LogLevel (default)
  --no-remove-defaults: do not touch UserDefaults
  --dry-run           : print actions without making changes
EOF
}

if [ "$#" -lt 1 ]; then
  usage
  exit 1
fi

INPUT="$1"
shift || true

REMOVE_DEFAULTS=true
DRY_RUN=false

while [ "$#" -gt 0 ]; do
  case "$1" in
    --remove-defaults) REMOVE_DEFAULTS=true; shift ;;
    --no-remove-defaults) REMOVE_DEFAULTS=false; shift ;;
    --dry-run) DRY_RUN=true; shift ;;
    -h|--help) usage; exit 0;;
    *) echo "Unknown option: $1"; usage; exit 1;;
  esac
done

# If INPUT is an app bundle path, try to read CFBundleIdentifier
if [[ "$INPUT" == *.app ]]; then
  APP_PATH="$INPUT"
  INFO_PLIST="$APP_PATH/Contents/Info.plist"
  if [ ! -f "$INFO_PLIST" ]; then
    echo "Info.plist not found in $APP_PATH"
    exit 2
  fi
  if command -v /usr/libexec/PlistBuddy >/dev/null 2>&1; then
    BUNDLE_ID=$(/usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" "$INFO_PLIST" 2>/dev/null || true)
  else
    BUNDLE_ID=$(defaults read "$INFO_PLIST" CFBundleIdentifier 2>/dev/null || true)
  fi
  if [ -z "$BUNDLE_ID" ]; then
    echo "Failed to read CFBundleIdentifier from $INFO_PLIST"
    exit 3
  fi
else
  BUNDLE_ID="$INPUT"
fi

APP_SUPPORT_DIR="$HOME/Library/Application Support/$BUNDLE_ID"
FLAG_FILE="$APP_SUPPORT_DIR/enable_full_debug"
LOG_FILE="$APP_SUPPORT_DIR/Man1fest0.log"

echo "Bundle Identifier: $BUNDLE_ID"
echo "Application Support dir: $APP_SUPPORT_DIR"
echo "Flag file: $FLAG_FILE"
echo "Log file (expected): $LOG_FILE"

if [ "$DRY_RUN" = true ]; then
  echo "[DRY RUN] Would remove flag file: $FLAG_FILE"
  if [ "$REMOVE_DEFAULTS" = true ]; then
    echo "[DRY RUN] Would run: defaults delete $BUNDLE_ID Man1fest0LogLevel"
  else
    echo "[DRY RUN] Skipping defaults removal"
  fi
  exit 0
fi

if [ -f "$FLAG_FILE" ]; then
  rm "$FLAG_FILE"
  echo "Removed flag file: $FLAG_FILE"
else
  echo "Flag file not found (already removed): $FLAG_FILE"
fi

if [ "$REMOVE_DEFAULTS" = true ]; then
  # Try to delete the key; ignore non-zero if key doesn't exist
  defaults delete "$BUNDLE_ID" Man1fest0LogLevel 2>/dev/null || true
  echo "Removed UserDefaults key Man1fest0LogLevel for bundle: $BUNDLE_ID"
fi

echo "Verbose logging disabled (flag file removed)."
