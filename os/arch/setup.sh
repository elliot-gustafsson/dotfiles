#!/bin/bash
set -e

# --- CONFIGURATION VARIABLES ---
HOSTNAME="arch-gnome"
USERNAME="user"
TIMEZONE="Europe/Stockholm"
KEYMAP="sv-latin1"
LOCALE="en_US.UTF-8"

echo "==================================================="
echo "   ARCH LINUX (GNOME + AURA RUST + NVIDIA CHECK)   "
echo "==================================================="

# 1. DISK SELECTION
lsblk
echo ""
read -p "Enter the TARGET DISK (e.g., /dev/nvme0n1 or /dev/sda): " DISK

if [ -z "$DISK" ]; then echo "Error: No disk specified."; exit 1; fi

echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
echo "WARNING: ALL DATA ON $DISK WILL BE DESTROYED."
echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
read -p "Are you absolutely sure? (Type 'YES' to proceed): " CONFIRM
if [ "$CONFIRM" != "YES" ]; then echo "Aborting."; exit 1; fi

# 2. PARTITIONING
echo "--> Partitioning $DISK..."
sgdisk -Z "$DISK"
sgdisk -a 2048 -o "$DISK"

# Part 1: EFI (512M)
# Part 2: Root (Remaining)
sgdisk -n 1::+512M -t 1:ef00 -c 1:"EFI System" "$DISK"
sgdisk -n 2::-0    -t 2:8300 -c 2:"Arch Linux" "$DISK"

# Handle naming variation
if [[ "$DISK" == *"nvme"* ]]; then
    PART1="${DISK}p1"
    PART2="${DISK}p2"
else
    PART1="${DISK}1"
    PART2="${DISK}2"
fi

# 3. FORMATTING & SUBVOLUMES
echo "--> Formatting partitions..."
mkfs.vfat -F32 -n "EFI" "$PART1"
mkfs.btrfs -L "Arch" -f "$PART2"

echo "--> Creating Btrfs Subvolumes (Flat Layout)..."
mount "$PART2" /mnt
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@snapshots
btrfs subvolume create /mnt/@snapshots_home
btrfs subvolume create /mnt/@log
btrfs subvolume create /mnt/@cache
umount /mnt

# 4. MOUNTING
echo "--> Mounting subvolumes..."
MOUNT_OPT="compress=zstd:1,noatime"
mount -o $MOUNT_OPT,subvol=@ "$PART2" /mnt
mkdir -p /mnt/{home,boot,var/log,var/cache,.snapshots}
mkdir -p /mnt/home/.snapshots

mount -o $MOUNT_OPT,subvol=@home "$PART2" /mnt/home
mount -o $MOUNT_OPT,subvol=@log "$PART2" /mnt/var/log
mount -o $MOUNT_OPT,subvol=@cache "$PART2" /mnt/var/cache
mount -o $MOUNT_OPT,subvol=@snapshots "$PART2" /mnt/.snapshots
mount -o $MOUNT_OPT,subvol=@snapshots_home "$PART2" /mnt/home/.snapshots
mount "$PART1" /mnt/boot

# 5. NVIDIA CHECK & BASE INSTALL
echo "--> Preparing for System Installation..."

# --- NVIDIA DETECTION & CONFIG ---
NVIDIA_PACKAGES=""
SETUP_NVIDIA_GRUB="false"

if lspci | grep -i "nvidia" > /dev/null; then
    echo ""
    echo "---------------------------------------------------"
    echo "  [!] NVIDIA GPU DETECTED"
    echo "---------------------------------------------------"
    read -p "Do you want to install proprietary NVIDIA drivers? (y/N): " NVID_CHOICE
    if [[ "$NVID_CHOICE" =~ ^[Yy]$ ]]; then
        echo "--> NVIDIA drivers will be installed."
        NVIDIA_PACKAGES="nvidia nvidia-utils nvidia-settings"
        SETUP_NVIDIA_GRUB="true"
    else
        echo "--> Using open-source (Nouveau) drivers."
    fi
else
    echo "--> No NVIDIA GPU detected (or logic skipped)."
fi
echo ""

echo "--> Installing System Packages..."
# Added 'rust' here so we can compile Aura later
pacstrap /mnt \
    base \
    linux \
    linux-firmware \
    btrfs-progs \
    grub \
    efibootmgr \
    networkmanager \
    sudo \
    man-db \
    man-pages \
    texinfo \
    gnome \
    gdm \
    vim \
    git \
    base-devel \
    gnome-terminal \
    pipewire \
    pipewire-pulse \
    pipewire-alsa \
    pipewire-jack \
    wireplumber \
    snapper \
    snap-pac \
    firefox \
    bind \
    whois \
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
    ripgrep \
    $NVIDIA_PACKAGES

# Generate Fstab
genfstab -U /mnt >> /mnt/etc/fstab

# Pass the NVIDIA choice to the chroot
if [ "$SETUP_NVIDIA_GRUB" = "true" ]; then
    touch /mnt/root/.install_nvidia_config
fi

# 6. SYSTEM CONFIGURATION (CHROOT)
echo "--> Configuring System inside Chroot..."

cat <<EOF > /mnt/root/setup_internal.sh
#!/bin/bash
set -e

# Time & Lang
ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime
hwclock --systohc
sed -i 's/#$LOCALE/$LOCALE/' /etc/locale.gen
locale-gen
echo "LANG=$LOCALE" > /etc/locale.conf
echo "KEYMAP=$KEYMAP" > /etc/vconsole.conf
echo "$HOSTNAME" > /etc/hostname

# Network
systemctl enable NetworkManager
systemctl enable gdm

# Root Password
echo "--> Set ROOT password:"
passwd

# User Setup
echo "--> Creating user: $USERNAME"
useradd -m -G wheel -s /bin/bash "$USERNAME"
echo "--> Set USER password for $USERNAME:"
passwd "$USERNAME"

# Sudo (Passwordless for Wheel temporarily)
echo "%wheel ALL=(ALL:ALL) NOPASSWD: ALL" > /etc/sudoers.d/wheel

# GRUB Setup
echo "--> Installing GRUB..."
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB

# --- NVIDIA GRUB CONFIG ---
if [ -f /root/.install_nvidia_config ]; then
    echo "--> Configuring GRUB for NVIDIA (DRM Modeset)..."
    sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="/GRUB_CMDLINE_LINUX_DEFAULT="nvidia_drm.modeset=1 /' /etc/default/grub
    rm /root/.install_nvidia_config
fi

# --- SNAPPER CONFIGURATION ---
echo "--> Configuring Snapper..."

# 1. Root Config
umount /.snapshots
rm -r /.snapshots
snapper -c root create-config /
btrfs subvolume delete /.snapshots
mkdir /.snapshots
mount -a
chmod 750 /.snapshots

# 2. Home Config
umount /home/.snapshots
rm -r /home/.snapshots
snapper -c home create-config /home
btrfs subvolume delete /home/.snapshots
mkdir /home/.snapshots
mount -a
chmod 750 /home/.snapshots
chown :$USERNAME /home/.snapshots

# 3. Tuning Retention
sed -i 's/TIMELINE_LIMIT_HOURLY="10"/TIMELINE_LIMIT_HOURLY="5"/' /etc/snapper/configs/root
sed -i 's/TIMELINE_LIMIT_DAILY="10"/TIMELINE_LIMIT_DAILY="7"/' /etc/snapper/configs/root
sed -i 's/TIMELINE_LIMIT_WEEKLY="0"/TIMELINE_LIMIT_WEEKLY="0"/' /etc/snapper/configs/root
sed -i 's/TIMELINE_LIMIT_MONTHLY="10"/TIMELINE_LIMIT_MONTHLY="0"/' /etc/snapper/configs/root
sed -i 's/TIMELINE_LIMIT_YEARLY="10"/TIMELINE_LIMIT_YEARLY="0"/' /etc/snapper/configs/root

cp /etc/snapper/configs/root /etc/snapper/configs/home
sed -i "s/ALLOW_USERS=\"\"/ALLOW_USERS=\"$USERNAME\"/" /etc/snapper/configs/home

# --- AUR (AURA SOURCE) INSTALLATION ---
echo "--> Compiling Aura and Installing Tools..."
# Note: This will download crates and compile. It may take a moment.

cd /home/$USERNAME
sudo -u $USERNAME git clone https://aur.archlinux.org/aura.git
cd aura
makepkg -sf
find "*.pkg.tar.zst" | grep -v debug | xargs sudo pacman -U --noconfirm
cd ..
rm -rf aura

# Install Tools using Aura
sudo -u $USERNAME aura -A --noconfirm snapper-rollback vscodium-bin

# Configure snapper-rollback
cat <<CONF > /etc/snapper-rollback.conf
[root]
subvol_main = @
subvol_snapshots = @snapshots
CONF

# Enable Services
systemctl enable grub-btrfsd
systemctl enable snapper-timeline.timer
systemctl enable snapper-boot.timer

# Final GRUB Config
grub-mkconfig -o /boot/grub/grub.cfg

# Revert sudoers
echo "%wheel ALL=(ALL:ALL) ALL" > /etc/sudoers.d/wheel

EOF

# Execute the chroot script
chmod +x /mnt/root/setup_internal.sh
arch-chroot /mnt /root/setup_internal.sh

# Cleanup
rm /mnt/root/setup_internal.sh

echo "==================================================="
echo "   INSTALLATION COMPLETE!"
echo "   Type 'reboot' to restart into Gnome."
echo "==================================================="
