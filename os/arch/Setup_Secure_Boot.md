# Setup Secure Boot Arch #

### 1: Clear Secure Boot Keys in BIOS ###
* Key management should be set to "Custom", "Default" is default
* Go to the bios and clear secure boot keys, Boot -> Secure Boot -> Key Management

### 2: Install and generate keys ###
* `sudo pacman -S sbctl`
* `sudo sbctl status` Note: "Setup Mode" should be "Enabled", if not, redo step 1
* `sudo sbctl create keys`
* `sudo sbctl enroll-keys -m` Note: -m is imporant to include Microsoft keys so that dual booting with Windows is possible

### 3: Grub Fixes ###
Note: disables shim and tell grub to use tpm to verify files
* `sudo grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=arch --modules="tpm" --disable-shim-lock`

### 4: Sign boot files ###
* Check which files need signing: `sudo sbctl verify`
* Sign files with: `sudo sbctl sign -s <file>`

### 5: Verify ###
* Enable secureboot in bios (Windows UEFI Mode)
* If arch boots correctly, check: `sbctl status`. All checks should be green.

```
$ sbctl status
Installed:      ✓ sbctl is installed
Owner GUID:     <uuid>
Setup Mode:     ✓ Disabled
Secure Boot:    ✓ Enabled
Vendor Keys:    microsoft
```

#### 5.1: Dual boot entries fix ####
If you get dual boot entries you can remove the old one using:
* Check entries: `efibootmgr`
* Remove the old one using: `sudo efibootmgr -b XXXX -B`
* "arch" is the one we just created, remove the one named "UEFI OS", ex: `sudo efibootmgr -b 0005 -B`


```
$ efibootmgr
BootCurrent: 0001
Timeout: 1 seconds
BootOrder: 0001,0000,0005
Boot0000* Windows Boot Manager ...
Boot0001* arch ...
Boot0005* UEFI OS ...
```
