#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="$ROOT_DIR/.state"
LOG_FILE="$LOG_DIR/bootstrap-$(date +%Y%m%d-%H%M%S).log"
MISSING_FILE="$LOG_DIR/missing-apt-packages.txt"

mkdir -p "$LOG_DIR"
exec > >(tee -a "$LOG_FILE") 2>&1

if [[ "$EUID" -eq 0 ]]; then
  printf 'Run this script as your normal desktop user, not as root.\n' >&2
  exit 1
fi

if [[ ! -r /etc/os-release ]]; then
  printf 'Cannot identify the operating system.\n' >&2
  exit 1
fi

. /etc/os-release
if [[ "${ID:-}" != debian || "${VERSION_CODENAME:-}" != trixie ]]; then
  printf 'This snapshot targets Debian 13 trixie. Current system: %s %s.\n' "${ID:-unknown}" "${VERSION_CODENAME:-unknown}" >&2
  exit 1
fi

printf 'Debian KDE bootstrap starting. Log: %s\n' "$LOG_FILE"
sudo -v

"$ROOT_DIR/scripts/restore-apt-sources.sh"

# Keep package installation fully unattended. `apt-get -y` only confirms APT's
# own questions; package-specific debconf dialogs otherwise still open.
APT_ENV=(
  DEBIAN_FRONTEND=noninteractive
  DEBCONF_NONINTERACTIVE_SEEN=true
  APT_LISTCHANGES_FRONTEND=none
  NEEDRESTART_MODE=a
)
APT_OPTIONS=(
  -y
  -o Dpkg::Options::=--force-confold
  -o Dpkg::Use-Pty=0
)

# Preserve the safe default: do not randomize the MAC address automatically.
printf '%s\n' 'macchanger macchanger/automatically_run boolean false' \
  | sudo debconf-set-selections

# Recover cleanly when a previous bootstrap was interrupted during dpkg setup.
sudo env "${APT_ENV[@]}" dpkg --configure -a

mapfile -t requested_packages < <(grep -Ev '^[[:space:]]*(#|$)' "$ROOT_DIR/manifests/apt-manual.txt" | sort -u)
available_packages=()
missing_packages=()
has_nvidia=0
if lspci -nn 2>/dev/null | grep -qi 'NVIDIA'; then
  has_nvidia=1
fi

for package_name in "${requested_packages[@]}"; do
  if (( has_nvidia == 0 )) && [[ "$package_name" =~ ^(nvidia|libnvidia|cuda-keyring) ]]; then
    printf 'Skipping NVIDIA package on non-NVIDIA hardware: %s\n' "$package_name"
    continue
  fi
  if apt-cache show "$package_name" >/dev/null 2>&1; then
    available_packages+=("$package_name")
  else
    missing_packages+=("$package_name")
  fi
done

printf '%s\n' "${missing_packages[@]:-}" | sed '/^$/d' > "$MISSING_FILE"

install_batch() {
  local -a batch=("$@")
  (( ${#batch[@]} > 0 )) || return 0
  if ! sudo env "${APT_ENV[@]}" apt-get "${APT_OPTIONS[@]}" install "${batch[@]}"; then
    printf 'A package batch failed; retrying its packages individually.\n'
    for package_name in "${batch[@]}"; do
      sudo env "${APT_ENV[@]}" apt-get "${APT_OPTIONS[@]}" install "$package_name" \
        || printf 'Failed APT package: %s\n' "$package_name" >> "$MISSING_FILE"
    done
  fi
}

batch=()
for package_name in "${available_packages[@]}"; do
  batch+=("$package_name")
  if (( ${#batch[@]} >= 40 )); then
    install_batch "${batch[@]}"
    batch=()
  fi
done
install_batch "${batch[@]}"
sort -u -o "$MISSING_FILE" "$MISSING_FILE"

if command -v flatpak >/dev/null 2>&1; then
  while IFS=$'\t' read -r remote_name remote_url _; do
    [[ -n "$remote_name" && -n "$remote_url" ]] || continue
    sudo flatpak remote-add --if-not-exists "$remote_name" "$remote_url"
  done < "$ROOT_DIR/manifests/flatpak-remotes.tsv"

  while IFS=$'\t' read -r app_id origin branch _; do
    [[ -n "$app_id" ]] || continue
    sudo flatpak install --noninteractive -y "${origin:-flathub}" "$app_id" "${branch:-stable}" || true
  done < "$ROOT_DIR/manifests/flatpak-apps.tsv"
fi

if command -v codium >/dev/null 2>&1; then
  while IFS= read -r extension_spec; do
    [[ -n "$extension_spec" ]] || continue
    codium --install-extension "$extension_spec" --force || true
  done < "$ROOT_DIR/manifests/codium-extensions.txt"
fi

"$ROOT_DIR/scripts/restore-dotfiles.sh"
"$ROOT_DIR/scripts/restore-services.sh"

printf '\nBootstrap complete.\n'
if [[ -s "$MISSING_FILE" ]]; then
  printf 'Packages requiring manual attention: %s\n' "$MISSING_FILE"
fi
printf 'Log out and back in, or reboot, to reload all Plasma settings.\n'
