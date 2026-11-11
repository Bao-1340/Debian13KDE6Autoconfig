#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE_DIR="$ROOT_DIR/dotfiles/home"
STATE_DIR="$HOME/.local/state/debian-kde-bootstrap"
BACKUP_DIR="$STATE_DIR/backups/$(date +%Y%m%d-%H%M%S)"

if [[ ! -d "$SOURCE_DIR" ]]; then
  printf 'Dotfile snapshot is missing: %s\n' "$SOURCE_DIR" >&2
  exit 1
fi

mkdir -p "$BACKUP_DIR"

while IFS= read -r -d '' source_path; do
  relative_path="${source_path#"$SOURCE_DIR"/}"
  destination_path="$HOME/$relative_path"
  if [[ -f "$destination_path" || -L "$destination_path" ]]; then
    mkdir -p "$BACKUP_DIR/$(dirname -- "$relative_path")"
    cp -a -- "$destination_path" "$BACKUP_DIR/$relative_path"
  fi
done < <(find "$SOURCE_DIR" \( -type f -o -type l \) -print0)

cp -a -- "$SOURCE_DIR/." "$HOME/"

source_home=''
if [[ -r "$ROOT_DIR/manifests/source-system.env" ]]; then
  # This file is generated locally and contains only shell-escaped scalar values.
  # shellcheck disable=SC1091
  source "$ROOT_DIR/manifests/source-system.env"
  source_home="${SOURCE_HOME:-}"
fi

if [[ -n "$source_home" && "$source_home" != "$HOME" ]]; then
  while IFS= read -r -d '' restored_file; do
    if file --brief --mime-type "$restored_file" | grep -q '^text/'; then
      sed -i "s#${source_home//\#/\\#}#$HOME#g" "$restored_file"
    fi
  done < <(find "$SOURCE_DIR" -type f -print0 | while IFS= read -r -d '' original_file; do
    printf '%s\0' "$HOME/${original_file#"$SOURCE_DIR"/}"
  done)
fi

fc-cache -f >/dev/null 2>&1 || true
systemctl --user daemon-reload 2>/dev/null || true
printf 'Previous configuration backup: %s\n' "$BACKUP_DIR"
