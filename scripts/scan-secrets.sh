#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
SCAN_PATHS=("$ROOT_DIR/dotfiles" "$ROOT_DIR/system")
found=0

printf 'Scanning exported files for obvious secrets...\n'

while IFS= read -r suspicious_file; do
  printf 'Suspicious filename: %s\n' "${suspicious_file#"$ROOT_DIR"/}"
  found=1
done < <(
  find "${SCAN_PATHS[@]}" -type f \
    \( -iname '*.pem' -o -iname '*.p12' -o -iname '*.pfx' \
       -o -iname 'id_rsa*' -o -iname 'id_ed25519*' \
       -o -iname '*credentials*' -o -iname '*.kdbx' \) -print 2>/dev/null
)

secret_pattern='BEGIN ([A-Z ]+ )?PRIVATE KEY|AKIA[0-9A-Z]{16}|gh[pousr]_[A-Za-z0-9_]{20,}|://[^/@[:space:]]+:[^/@[:space:]]+@|"(password|passwd|token|api[_-]?key|client[_-]?secret)"[[:space:]]*:[[:space:]]*"[^"[:space:]]{4,}"'

while IFS= read -r matched_file; do
  printf 'Possible secret content: %s\n' "${matched_file#"$ROOT_DIR"/}"
  found=1
done < <(grep -RIlE --binary-files=without-match "$secret_pattern" "${SCAN_PATHS[@]}" 2>/dev/null || true)

if (( found != 0 )); then
  printf 'Secret scan failed. Review or remove the reported files before committing.\n' >&2
  exit 1
fi

printf 'Secret scan passed.\n'
