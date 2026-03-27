#!/usr/bin/env bash
# Build Meditation Tracker for Forerunner 255 Music.
# Uses Connect IQ SDK: add its bin to PATH, or we try the default macOS SDK path.

set -e
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

MONKEYC="monkeyc"
if ! command -v monkeyc &>/dev/null; then
  SDK_BASE="$HOME/Library/Application Support/Garmin/ConnectIQ/Sdks"
  if [ -d "$SDK_BASE" ]; then
    SDK_DIR=$(find "$SDK_BASE" -maxdepth 1 -type d -name 'connectiq-sdk-mac-*' 2>/dev/null | head -1)
    if [ -n "$SDK_DIR" ] && [ -x "$SDK_DIR/bin/monkeyc" ]; then
      MONKEYC="$SDK_DIR/bin/monkeyc"
    fi
  fi
  if [ "$MONKEYC" = "monkeyc" ]; then
    SDK_LEGACY="$HOME/Library/Application Support/Garmin/Connect IQ/Sdks/connectiq-sdk/bin/monkeyc"
    if [ -x "$SDK_LEGACY" ]; then
      MONKEYC="$SDK_LEGACY"
    fi
  fi
  if [ "$MONKEYC" = "monkeyc" ]; then
    echo "monkeyc not found. Add the SDK bin folder to PATH."
    echo "Or use the Monkey C VS Code extension and Connect IQ: Build."
    exit 1
  fi
fi

mkdir -p bin
EXTRA_ARGS=()
if [ -n "$DEVELOPER_KEY" ] && [ -f "$DEVELOPER_KEY" ]; then
  EXTRA_ARGS=(-y "$DEVELOPER_KEY")
fi
if ! "$MONKEYC" -f monkey.jungle -o bin/MeditationTracker.prg -d fr255m "${EXTRA_ARGS[@]}"; then
  if [ ${#EXTRA_ARGS[@]} -eq 0 ]; then
    echo ""
    echo "SDK may require a signing key. Run: DEVELOPER_KEY=/path/to/your.der ./scripts/build.sh"
  fi
  exit 1
fi
echo "Built: bin/MeditationTracker.prg"
