#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
MANIFEST_DIR="$ROOT_DIR/manifests"
DOTFILES_DIR="$ROOT_DIR/dotfiles/home"
APT_EXPORT_DIR="$ROOT_DIR/system/apt"
REFERENCE_DIR="$ROOT_DIR/reference"

mkdir -p "$MANIFEST_DIR" "$DOTFILES_DIR" "$REFERENCE_DIR"
mkdir -p "$APT_EXPORT_DIR/etc/apt/sources.list.d"
mkdir -p "$APT_EXPORT_DIR/etc/apt/trusted.gpg.d"
mkdir -p "$APT_EXPORT_DIR/usr/share/keyrings"

copy_home_path() {
  local relative_path="$1"
  local source_path="$HOME/$relative_path"
  local target_path="$DOTFILES_DIR/$relative_path"
  if [[ -d "$source_path" ]]; then
    mkdir -p "$target_path"
    cp -a -- "$source_path/." "$target_path/"
  elif [[ -e "$source_path" ]]; then
    mkdir -p "$(dirname -- "$target_path")"
    cp -a -- "$source_path" "$target_path"
  fi
}

copy_system_file() {
  local source_path="$1"
  local relative_path="${source_path#/}"
  local target_path="$APT_EXPORT_DIR/$relative_path"
  if [[ -f "$source_path" ]]; then
    mkdir -p "$(dirname -- "$target_path")"
    cp -a -- "$source_path" "$target_path"
  fi
}

normalize_exported_text() {
  local exported_file
  while IFS= read -r -d '' exported_file; do
    # Skip binary signing keys and empty files. This keeps generated snapshots
    # stable and prevents insignificant trailing whitespace from polluting Git.
    if grep -Iq '' "$exported_file"; then
      perl -0pi -e 's/[ \t]+\n/\n/g; s/\n+\z/\n/' "$exported_file"
    fi
  done < <(
    find "$MANIFEST_DIR" "$DOTFILES_DIR" "$REFERENCE_DIR" "$ROOT_DIR/scripts" \
      -type f -print0
    printf '%s\0' \
      "$ROOT_DIR/.gitignore" \
      "$ROOT_DIR/README.md" \
      "$ROOT_DIR/bootstrap.sh" \
      "$ROOT_DIR/export-current-state.sh" \
      "$ROOT_DIR/verify.sh"
  )
}

export LC_ALL=C

apt-mark showmanual | sort -u > "$MANIFEST_DIR/apt-manual.txt"
dpkg-query -W -f='${binary:Package}\t${Version}\t${Architecture}\t${db:Status-Abbrev}\n' \
  | sort -u > "$MANIFEST_DIR/dpkg-installed.tsv"

if command -v flatpak >/dev/null 2>&1; then
  flatpak list --app --columns=application,origin,branch,arch \
    | sort -u > "$MANIFEST_DIR/flatpak-apps.tsv"
  flatpak remotes --columns=name,url,filter,options \
    | sort -u > "$MANIFEST_DIR/flatpak-remotes.tsv"
else
  : > "$MANIFEST_DIR/flatpak-apps.tsv"
  : > "$MANIFEST_DIR/flatpak-remotes.tsv"
fi

if command -v codium >/dev/null 2>&1; then
  codium --list-extensions --show-versions 2>/dev/null \
    | sort -u > "$MANIFEST_DIR/codium-extensions.txt"
else
  : > "$MANIFEST_DIR/codium-extensions.txt"
fi

systemctl list-unit-files --state=enabled --no-legend --no-pager 2>/dev/null \
  | awk '{print $1}' | sort -u > "$MANIFEST_DIR/systemd-enabled.txt" || true
systemctl --user list-unit-files --state=enabled --no-legend --no-pager 2>/dev/null \
  | awk '{print $1}' | sort -u > "$MANIFEST_DIR/systemd-user-enabled.txt" || true

{
  printf 'SOURCE_HOME=%q\n' "$HOME"
  printf 'SOURCE_USER=%q\n' "$USER"
  printf 'ARCH=%q\n' "$(dpkg --print-architecture)"
  . /etc/os-release
  printf 'DEBIAN_VERSION=%q\n' "$VERSION_ID"
  printf 'DEBIAN_CODENAME=%q\n' "$VERSION_CODENAME"
  printf 'EXPORTED_AT=%q\n' "$(date --iso-8601=seconds)"
} > "$MANIFEST_DIR/source-system.env"

{
  uname -a
  lscpu
  printf '\nPCI:\n'
  lspci -nnk
  printf '\nBLOCK DEVICES:\n'
  lsblk -o NAME,SIZE,FSTYPE,MODEL,TYPE,MOUNTPOINTS
} > "$REFERENCE_DIR/hardware-summary.txt"

find "$HOME/.local/bin" -maxdepth 3 -type f -printf '%s\t%p\n' 2>/dev/null \
  | sort -nr > "$REFERENCE_DIR/local-bin-inventory.tsv" || true
find /usr/local/bin /usr/local/sbin -maxdepth 1 -type f -printf '%s\t%p\n' 2>/dev/null \
  | sort -nr > "$REFERENCE_DIR/system-local-bin-inventory.tsv" || true

copy_system_file /etc/apt/sources.list
while IFS= read -r source_file; do
  copy_system_file "$source_file"
done < <(find /etc/apt/sources.list.d -maxdepth 1 -type f \( -name '*.list' -o -name '*.sources' \) -print 2>/dev/null | sort)

for key_file in \
  /etc/apt/trusted.gpg.d/insynchq.gpg \
  /etc/apt/trusted.gpg.d/home_hmtheboy154.gpg \
  /usr/share/keyrings/freedownloadmanager.gpg \
  /usr/share/keyrings/chatgpt-archive-keyring.gpg \
  /usr/share/keyrings/cuda-archive-keyring.gpg; do
  copy_system_file "$key_file"
done

# Constrain the openSUSE Build Service key to this repository instead of
# trusting it globally during a future restore.
obs_source="$APT_EXPORT_DIR/etc/apt/sources.list.d/home:hmtheboy154.list"
if [[ -f "$obs_source" ]] && ! grep -q 'signed-by=' "$obs_source"; then
  sed -i 's#^deb #deb [signed-by=/etc/apt/trusted.gpg.d/home_hmtheboy154.gpg] #' "$obs_source"
fi

for relative_path in \
  .bashrc \
  .profile \
  .zshrc \
  .config/kdeglobals \
  .config/dolphinrc \
  .config/kaccessrc \
  .config/kactivitymanagerdrc \
  .config/kglobalshortcutsrc \
  .config/konsolerc \
  .config/kscreenlockerrc \
  .config/ksmserverrc \
  .config/kwinrc \
  .config/kxkbrc \
  .config/plasma-localerc \
  .config/plasma-org.kde.plasma.desktop-appletsrc \
  .config/plasmarc \
  .config/plasmashellrc \
  .config/gtk-3.0 \
  .config/gtk-4.0 \
  .config/environment.d \
  .config/autostart \
  .config/VSCodium/User/settings.json \
  .config/VSCodium/User/keybindings.json \
  .config/VSCodium/User/snippets \
  .config/wireshark/preferences \
  .config/wireshark/colorfilters \
  .config/wireshark/dfilters \
  .local/share/konsole \
  .local/share/applications; do
  copy_home_path "$relative_path"
done

normalize_exported_text
"$ROOT_DIR/scripts/scan-secrets.sh"
printf 'Snapshot exported to %s\n' "$ROOT_DIR"
