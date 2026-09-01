#!/bin/bash
set -e

cd "$HOME" || exit

sudo pacman -Fy

# Install some stuff
sudo pacman -S --needed --noconfirm \
    base-devel \
    bind \
    whois \
    firefox \
    ghostty \
    git \
    nvim \
    fzf \
    ttf-hack-nerd \
    k9s \
    jq \
    nmap \
    bash-completion \
    extension-manager \
    nvtop \
    less \
    podman \
    podman-docker \
    snapper

fc-cache -fv

mkdir -p "$HOME/Projects"

if [ ! -d "$HOME/Projects/aura" ]; then
  git clone https://aur.archlinux.org/aura.git "$HOME/Projects/aura"
else
  cd "$HOME/Projects/aura" || exit
  git pull
  cd "$HOME" || exit
fi

cd "$HOME/Projects/aura" || exit
makepkg -sf
find "*.pkg.tar.zst" | grep -v debug | xargs sudo pacman -U --noconfirm
cd "$HOME" || exit

sudo aura -A --noconfirm vscodium-bin

gsettings set org.gnome.desktop.wm.preferences button-layout ":minimize,maximize,close"

###############################################################################
# Snapper + Btrfs setup
###############################################################################

setup_snapper() {
  set -euo pipefail

  local FSTAB="/etc/fstab"
  local MNT_TOP="/mnt/btrfs_top"
  local ROOT_SNAPS_SUBVOL="@snapshots"
  local HOME_SNAPS_SUBVOL="@home_snapshots"
  local ROOT_SNAPS_DIR="/.snapshots"
  local HOME_SNAPS_DIR="/home/.snapshots"

  # ---- FAST EXIT IF ALREADY CONFIGURED ----
  if [[ "$(findmnt -n -o FSTYPE /)" == "btrfs" ]] \
     && sudo snapper -c root list &>/dev/null \
     && sudo snapper -c home list &>/dev/null \
     && findmnt "$ROOT_SNAPS_DIR" &>/dev/null \
     && findmnt "$HOME_SNAPS_DIR" &>/dev/null \
     && findmnt "$ROOT_SNAPS_DIR" -n -o OPTIONS | grep -q "subvol=${ROOT_SNAPS_SUBVOL}" \
     && findmnt "$HOME_SNAPS_DIR" -n -o OPTIONS | grep -q "subvol=${HOME_SNAPS_SUBVOL}" \
     && grep -q "[[:space:]]${ROOT_SNAPS_DIR}[[:space:]].*subvol=${ROOT_SNAPS_SUBVOL}" "$FSTAB" \
     && grep -q "[[:space:]]${HOME_SNAPS_DIR}[[:space:]].*subvol=${HOME_SNAPS_SUBVOL}" "$FSTAB"
  then
    echo "==> Snapper already configured, nothing to do"
    return 0
  fi

  local ROOT_SOURCE
  ROOT_SOURCE="$(findmnt / -n -o SOURCE | sed 's/\[.*\]//')"

  local UUID
  UUID="$(findmnt -n -o UUID /)"

  sudo mkdir -p "$MNT_TOP"
  mountpoint -q "$MNT_TOP" || sudo mount -o subvolid=5 "$ROOT_SOURCE" "$MNT_TOP"

  sudo snapper -c root list &>/dev/null || sudo snapper -c root create-config /
  sudo snapper -c home list &>/dev/null || sudo snapper -c home create-config /home

  sudo btrfs subvolume show "$ROOT_SNAPS_DIR" &>/dev/null \
    && sudo btrfs subvolume delete "$ROOT_SNAPS_DIR"

  sudo btrfs subvolume show "$HOME_SNAPS_DIR" &>/dev/null \
    && sudo btrfs subvolume delete "$HOME_SNAPS_DIR"

  sudo mkdir -p "$ROOT_SNAPS_DIR" "$HOME_SNAPS_DIR"
  sudo chmod a+rx "$ROOT_SNAPS_DIR" "$HOME_SNAPS_DIR"

  sudo btrfs subvolume show "$MNT_TOP/$ROOT_SNAPS_SUBVOL" &>/dev/null \
    || sudo btrfs subvolume create "$MNT_TOP/$ROOT_SNAPS_SUBVOL"

  sudo btrfs subvolume show "$MNT_TOP/$HOME_SNAPS_SUBVOL" &>/dev/null \
    || sudo btrfs subvolume create "$MNT_TOP/$HOME_SNAPS_SUBVOL"

  local ENTRY_ROOT="UUID=${UUID} ${ROOT_SNAPS_DIR} btrfs rw,relatime,compress=zstd:1,ssd,discard=async,space_cache=v2,subvol=${ROOT_SNAPS_SUBVOL} 0 0"
  local ENTRY_HOME="UUID=${UUID} ${HOME_SNAPS_DIR} btrfs rw,relatime,compress=zstd:1,ssd,discard=async,space_cache=v2,subvol=${HOME_SNAPS_SUBVOL} 0 0"

  grep -q "[[:space:]]${ROOT_SNAPS_DIR}[[:space:]]" "$FSTAB" || echo "$ENTRY_ROOT" | sudo tee -a "$FSTAB"
  grep -q "[[:space:]]${HOME_SNAPS_DIR}[[:space:]]" "$FSTAB" || echo "$ENTRY_HOME" | sudo tee -a "$FSTAB"

  sudo systemctl daemon-reload
  sudo mount -va

  sudo umount "$MNT_TOP"
  sudo rmdir "$MNT_TOP"

  snapper -c root list | grep -q "Root Initial" \
    || sudo snapper -c root create --description "Root Initial"

  snapper -c home list | grep -q "Home Initial" \
    || sudo snapper -c home create --description "Home Initial"

  echo "==> Snapper setup complete"
}

if command -v snapper &>/dev/null; then
  sudo pacman -S --needed --noconfirm grub-btrfs snap-pac
  sudo aura -A --noconfirm snapper-rollback
  # setup_snapper
  sudo systemctl enable --now grub-btrfsd snapper-timeline.timer snapper-boot.timer
fi
