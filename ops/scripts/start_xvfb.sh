#!/usr/bin/env bash
set -euo pipefail

: "${DISPLAY:=:0}"
: "${SCREEN_WIDTH:=1280}"
: "${SCREEN_HEIGHT:=800}"
: "${SCREEN_DEPTH:=24}"

if pgrep -f "Xvfb ${DISPLAY}" >/dev/null 2>&1; then
  echo "Xvfb already running on ${DISPLAY}"
  exit 0
fi

Xvfb "${DISPLAY}" -screen 0 "${SCREEN_WIDTH}x${SCREEN_HEIGHT}x${SCREEN_DEPTH}" -ac +extension RANDR +extension RENDER +extension GLX -nolisten tcp &
sleep 1

if ! xdpyinfo -display "${DISPLAY}" >/dev/null 2>&1; then
  echo "Failed to start Xvfb on ${DISPLAY}" >&2
  exit 1
fi

wait -n


