#!/usr/bin/env bash
set -euo pipefail

export DISPLAY=${DISPLAY:-:0}

if pgrep -f "xfce4-session" >/dev/null 2>&1; then
  echo "Xfce already running"
  exit 0
fi

# Start D-Bus for the session
if ! pgrep -f "/usr/bin/dbus-daemon --session" >/dev/null 2>&1; then
  dbus-launch >/dev/null 2>&1 || true
fi

startxfce4 &
sleep 2

if ! pgrep -f "xfce4-session" >/dev/null 2>&1; then
  echo "Failed to start Xfce session" >&2
  exit 1
fi

wait -n


