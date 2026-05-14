#!/usr/bin/env bash
# Enable verbose logging for Man1fest0
# Usage: enable_verbose.sh <bundle-id | path-to-app.app> [--set-defaults] [--dry-run]
# If the first arg is an .app bundle path, the script will attempt to read CFBundleIdentifier

set -euo pipefail

usage() {
  cat <<EOF
Usage: $0 <bundle-id | path-to-app.app> [--set-defaults] [--dry-run]

Examples:
  $0 com.example.Man1fest0         # enable flag file and set UserDefaults to verbose
  $0 /Applications/Man1fest0.app    # read bundle id from app and enable
  $0 com.example.Man1fest0 --dry-run
  $0 com.example.Man1fest0 --no-defaults

Options:
  --set-defaults   : also write defaults key Man1fest0LogLevel = 2 (verbose) (default)
  --no-defaults    : do not touch UserDefaults
  --dry-run        : print actions without making changes
EOF
}

if [ "$#" -lt 1 ]; then
  usage
  exit 1
fi

INPUT="$1"
shift || true

SET_DEFAULTS=true
DRY_RUN=false

while [ "$#" -gt 0 ]; do
  case "$1" in
    --set-defaults) SET_DEFAULTS=true; shift ;;
    --no-defaults) SET_DEFAULTS=false; shift ;;
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
    # Fallback to defaults read (may fail for raw plist file)
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
  echo "[DRY RUN] Would create directory: $APP_SUPPORT_DIR"
  echo "[DRY RUN] Would create flag file: $FLAG_FILE"
  if [ "$SET_DEFAULTS" = true ]; then
    echo "[DRY RUN] Would run: defaults write $BUNDLE_ID Man1fest0LogLevel -int 2"
  else
    echo "[DRY RUN] Skipping defaults write"
  fi
  exit 0
fi

mkdir -p "$APP_SUPPORT_DIR"
# Create flag file (empty)
touch "$FLAG_FILE"
# Ensure log file exists
if [ ! -f "$LOG_FILE" ]; then
  touch "$LOG_FILE"
  echo "Created log file: $LOG_FILE"
fi

if [ "$SET_DEFAULTS" = true ]; then
  defaults write "$BUNDLE_ID" Man1fest0LogLevel -int 2
  echo "Wrote UserDefaults: $BUNDLE_ID Man1fest0LogLevel = 2"
fi

echo "Verbose logging enabled. Flag file created at: $FLAG_FILE"

echo "You can tail the log with:\n  tail -f \"$LOG_FILE\"" 
