#!/usr/bin/env bash
set -euo pipefail

check_port() {
  local host=$1
  local port=$2
  nc -z -w 2 "$host" "$port"
}

# Xvfb up?
if ! xdpyinfo -display "${DISPLAY:-:0}" >/dev/null 2>&1; then
  echo "X display not responding"
  exit 1
fi

# x11vnc/listening?
if ! check_port 127.0.0.1 5900; then
  echo "VNC port 5900 not open"
  exit 1
fi

# noVNC listening?
if ! check_port 127.0.0.1 6080; then
  echo "noVNC port 6080 not open"
  exit 1
fi

# Chrome running?
if ! pgrep -f "google-chrome" >/dev/null 2>&1; then
  echo "Chrome process not found"
  exit 1
fi

echo "OK"
exit 0


