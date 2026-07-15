#!/usr/bin/env bash

set -Eeuo pipefail

mapfile -t instances < <(
  dbus-send --session \
    --dest=org.freedesktop.DBus \
    --type=method_call \
    --print-reply \
    /org/freedesktop/DBus \
    org.freedesktop.DBus.ListNames \
    | grep -o 'org.pwmt.zathura.PID-[0-9]*' || true
)

for instance in "${instances[@]}"; do
  dbus-send --session \
    --dest="$instance" \
    --type=method_call \
    /org/pwmt/zathura \
    org.pwmt.zathura.ExecuteCommand \
    string:"source"
done
