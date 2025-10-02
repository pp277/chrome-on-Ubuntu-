#!/usr/bin/env bash
set -euo pipefail

export DISPLAY=${DISPLAY:-:0}
PROFILE_DIR=/home/chrome/profile
DOWNLOAD_DIR=/home/chrome/downloads

mkdir -p "$PROFILE_DIR" "$DOWNLOAD_DIR"

FLAGS=(
  --user-data-dir="$PROFILE_DIR"
  --disk-cache-dir="$PROFILE_DIR/cache"
  --disable-gpu
  --disable-software-rasterizer
  --no-first-run
  --no-default-browser-check
  --start-maximized
  --password-store=basic
  --force-device-scale-factor=1
)

if [ -n "${CHROME_FLAGS:-}" ]; then
  # shellcheck disable=SC2206
  EXTRA=(${CHROME_FLAGS})
  FLAGS+=("${EXTRA[@]}")
fi

if pgrep -f "google-chrome .*--user-data-dir=${PROFILE_DIR}" >/dev/null 2>&1; then
  echo "Chrome already running"
  exit 0
fi

/usr/bin/google-chrome "${FLAGS[@]}" about:blank &
sleep 2

if ! pgrep -f "google-chrome" >/dev/null 2>&1; then
  echo "Failed to start Chrome" >&2
  exit 1
fi

wait -n


