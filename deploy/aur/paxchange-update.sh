#!/bin/sh
set -e

if [ "$(id -u)" -eq 0 ] && [ -n "$SUDO_USER" ]; then
  exec sudo -u "$SUDO_USER" -- /usr/bin/paxchange update
else
  exec /usr/bin/paxchange update
fi
