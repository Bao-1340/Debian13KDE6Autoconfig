#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

restore_system_unit() {
  local unit_name="$1"
  [[ -n "$unit_name" ]] || return 0
  if [[ "$unit_name" == *@.* ]]; then
    printf 'Skipping template unit without an instance: %s\n' "$unit_name"
    return 0
  fi
  if systemctl cat "$unit_name" >/dev/null 2>&1; then
    sudo systemctl enable "$unit_name" >/dev/null 2>&1 \
      || printf 'Could not enable system unit: %s\n' "$unit_name"
  else
    printf 'System unit is unavailable: %s\n' "$unit_name"
  fi
}

restore_user_unit() {
  local unit_name="$1"
  [[ -n "$unit_name" ]] || return 0
  if [[ "$unit_name" == *@.* ]]; then
    printf 'Skipping user template unit without an instance: %s\n' "$unit_name"
    return 0
  fi
  if systemctl --user cat "$unit_name" >/dev/null 2>&1; then
    systemctl --user enable "$unit_name" >/dev/null 2>&1 \
      || printf 'Could not enable user unit: %s\n' "$unit_name"
  else
    printf 'User unit is unavailable: %s\n' "$unit_name"
  fi
}

while IFS= read -r unit_name; do
  restore_system_unit "$unit_name"
done < "$ROOT_DIR/manifests/systemd-enabled.txt"

while IFS= read -r unit_name; do
  restore_user_unit "$unit_name"
done < "$ROOT_DIR/manifests/systemd-user-enabled.txt"
