#!/usr/bin/env bash
set -euo pipefail

NOVNC_DIR=/opt/novnc

if pgrep -f "websockify --web ${NOVNC_DIR}" >/dev/null 2>&1; then
  echo "noVNC already running"
  exit 0
fi

cd "$NOVNC_DIR"
./utils/novnc_proxy --vnc localhost:5900 --listen 6080 &
sleep 1

if ! nc -z 127.0.0.1 6080; then
  echo "noVNC failed to bind to 6080" >&2
  exit 1
fi

wait -n


