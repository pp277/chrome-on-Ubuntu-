#!/usr/bin/env bash
set -euo pipefail

export DISPLAY=${DISPLAY:-:0}

if [ -z "${VNC_PASSWORD:-}" ]; then
  echo "VNC_PASSWORD must be set" >&2
  exit 1
fi

mkdir -p /home/chrome/.vnc
PASSFILE=/home/chrome/.vnc/passwd

if [ ! -f "$PASSFILE" ]; then
  x11vnc -storepasswd "$VNC_PASSWORD" "$PASSFILE"
  chmod 600 "$PASSFILE"
fi

if pgrep -f "x11vnc -display ${DISPLAY}" >/dev/null 2>&1; then
  echo "x11vnc already running"
  exit 0
fi

x11vnc -display "$DISPLAY" -rfbauth "$PASSFILE" -rfbport 5900 -shared -forever -nopw -tightfilexfer -ncache 10 -ncache_cr -quiet &
sleep 1

if ! nc -z 127.0.0.1 5900; then
  echo "x11vnc failed to bind to 5900" >&2
  exit 1
fi

wait -n


