#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
APT_EXPORT_DIR="$ROOT_DIR/system/apt"

if [[ ! -r /etc/os-release ]]; then
  printf 'Cannot identify the operating system.\n' >&2
  exit 1
fi

. /etc/os-release
if [[ "${ID:-}" != debian || "${VERSION_CODENAME:-}" != trixie ]]; then
  printf 'Refusing to restore APT sources: this snapshot targets Debian 13 trixie.\n' >&2
  exit 1
fi

APT_BACKUP_DIR="$HOME/.local/state/debian-kde-bootstrap/apt-backups/$(date +%Y%m%d-%H%M%S)"
mkdir -p "$APT_BACKUP_DIR"
if [[ -f /etc/apt/sources.list ]]; then
  sudo cp -a /etc/apt/sources.list "$APT_BACKUP_DIR/sources.list"
fi
if [[ -d /etc/apt/sources.list.d ]]; then
  sudo cp -a /etc/apt/sources.list.d "$APT_BACKUP_DIR/"
fi

install_exported_file() {
  local relative_path="$1"
  local source_path="$APT_EXPORT_DIR/$relative_path"
  local destination_path="/$relative_path"
  [[ -f "$source_path" ]] || return 0
  sudo install -D -m 0644 -- "$source_path" "$destination_path"
}

install_exported_file etc/apt/sources.list

while IFS= read -r source_file; do
  relative_path="${source_file#"$APT_EXPORT_DIR"/}"
  install_exported_file "$relative_path"
done < <(find "$APT_EXPORT_DIR/etc/apt/sources.list.d" -maxdepth 1 -type f -print 2>/dev/null | sort)

while IFS= read -r key_file; do
  relative_path="${key_file#"$APT_EXPORT_DIR"/}"
  install_exported_file "$relative_path"
done < <(find "$APT_EXPORT_DIR/etc/apt/trusted.gpg.d" "$APT_EXPORT_DIR/usr/share/keyrings" -type f -print 2>/dev/null | sort)

sudo apt-get update
printf 'Previous APT source backup: %s\n' "$APT_BACKUP_DIR"
