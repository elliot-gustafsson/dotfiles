# Setup snapper

Goal:

```
$ sudo btrfs subvolume list -p /
ID 256 gen 4532 parent 5 top level 5 path @
ID 257 gen 4532 parent 5 top level 5 path @home
ID 258 gen 4532 parent 5 top level 5 path @log
ID 259 gen 4392 parent 5 top level 5 path @pkg
ID 260 gen 12 parent 256 top level 256 path var/lib/portables
ID 261 gen 12 parent 256 top level 256 path var/lib/machines
ID 401 gen 4529 parent 5 top level 5 path @snapshots
ID 402 gen 4529 parent 5 top level 5 path @home_snapshots
```

### Create @snapshots and @home_snapshots if they dont exist
sudo mkdir -p /mnt/btrfs_top

DEVICE=$(findmnt / -n -o SOURCE | sed 's/\[.*\]//')

sudo mount -o subvolid=5 "/dev/$DEVICE" /mnt/btrfs_top

sudo snapper -c root create-config /
sudo snapper -c home create-config /home

sudo btrfs subvolume delete /.snapshots
sudo btrfs subvolume delete /home/.snapshots

sudo mkdir /.snapshots
sudo mkdir /home/.snapshots

sudo chmod a+rx /.snapshots/
sudo chmod a+rx /home/.snapshots/

sudo btrfs subvolume create /mnt/btrfs_top/@snapshots
sudo btrfs subvolume create /mnt/btrfs_top/@home_snapshots


UUID="$(findmnt -no UUID /)"

ENTRY_ROOT="UUID=${UUID} /.snapshots      btrfs rw,relatime,compress=zstd:1,ssd,discard=async,space_cache=v2,subvol=@snapshots 0 0"
ENTRY_HOME="UUID=${UUID} /home/.snapshots btrfs rw,relatime,compress=zstd:1,ssd,discard=async,space_cache=v2,subvol=@home_snapshots 0 0"

grep -q "[[:space:]]/.snapshots[[:space:]]" "$FSTAB" || \
    printf "\n%s\n" "$ENTRY_ROOT" | sudo tee -a "$FSTAB"

grep -q "[[:space:]]/home/.snapshots[[:space:]]" "$FSTAB" || \
    printf "\n%s\n" "$ENTRY_HOME" | sudo tee -a "$FSTAB"

sudo systemctl daemon-reload
sudo mount -va

sudo umount /mnt/btrfs_top
sudo rmdir /mnt/btrfs_top

sudo snapper -c root create --description "Root Initial"
sudo snapper -c home create --description "Home Initial"
