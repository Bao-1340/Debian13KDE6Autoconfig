#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

for script_file in \
  "$ROOT_DIR/bootstrap.sh" \
  "$ROOT_DIR/export-current-state.sh" \
  "$ROOT_DIR/scripts/restore-apt-sources.sh" \
  "$ROOT_DIR/scripts/restore-dotfiles.sh" \
  "$ROOT_DIR/scripts/restore-services.sh" \
  "$ROOT_DIR/scripts/scan-secrets.sh"; do
  bash -n "$script_file"
done

required_files=(
  "$ROOT_DIR/manifests/apt-manual.txt"
  "$ROOT_DIR/manifests/dpkg-installed.tsv"
  "$ROOT_DIR/manifests/source-system.env"
  "$ROOT_DIR/dotfiles/home/.zshrc"
)

for required_file in "${required_files[@]}"; do
  if [[ ! -s "$required_file" ]]; then
    printf 'Missing or empty required file: %s\n' "$required_file" >&2
    exit 1
  fi
done

"$ROOT_DIR/scripts/scan-secrets.sh"

printf 'APT manual packages: %s\n' "$(wc -l < "$ROOT_DIR/manifests/apt-manual.txt")"
printf 'Flatpak apps: %s\n' "$(wc -l < "$ROOT_DIR/manifests/flatpak-apps.tsv")"
printf 'VSCodium extensions: %s\n' "$(wc -l < "$ROOT_DIR/manifests/codium-extensions.txt")"
printf 'Verification passed.\n'
