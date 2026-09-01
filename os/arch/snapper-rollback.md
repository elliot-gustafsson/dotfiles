Here is the complete guide, fully formatted inside a single `.md` block.


# Snapper Rollback & Recovery Guide

This guide covers the three main recovery scenarios:
1. **Standard System Rollback:** Restoring the OS (`/`) when the system is bootable.
2. **Emergency System Rollback:** Restoring the OS (`/`) via the Boot Menu when the system won't boot.
3. **Home Data Recovery:** Restoring specific files in `/home` (documents, configs).


## 1. Standard System Rollback (Root)
*Use this method if your system boots, but is buggy (e.g., after a bad update or driver install).*

**Step 1: List your snapshots**
Find the snapshot number you want to return to (look at the dates).
```bash
sudo snapper -c root list
```

**Step 2: Execute the Rollback**
Replace `5` with the number of the "good" snapshot.

```bash
# sudo snapper --ambit classic rollback 5
sudo snapper-rollback 5
```

*Note: Snapper will create a backup of your CURRENT broken state before switching, just in case.*

**Step 3: Reboot**
You must reboot to load the older system state.

```bash
sudo reboot
```

---

## 2. Emergency System Rollback (Root)

*Use this method if you get a black screen or the system fails to start.*
*(Prerequisite: Requires `grub-btrfs` to be installed)*

**Step 1: Select Snapshot at Boot**

1. Power on your PC.
2. In the GRUB boot menu, select **"Btrfs Snapshots"** (or similar).
3. Choose a working snapshot from the list and press Enter.

**Step 2: Verify System**
The system will boot in **Read-Only** mode.

* Check if the issue is resolved (e.g., wifi works, desktop loads).
* *Note: You cannot save files or run updates in this mode.*

**Step 3: Make it Permanent**
If the snapshot works, run the rollback command on the running system. No number is required; Snapper detects the snapshot you are booted into.

```bash
# sudo snapper rollback
sudo snapper-rollback 5
```

**Step 4: Reboot**
Reboot normally to enter standard Read-Write mode.

```bash
sudo reboot
```

---

## 3. Home Data Recovery

*Use this to recover deleted files or overwrite corrupted configs in `/home`.*
**Important:** Do NOT run `snapper rollback` on `/home`. This creates a mess of users' data. Instead, copy specific files back.

**Step 1: Access the Hidden Snapshots**
Navigate to the hidden directory where home snapshots are mounted.

```bash
cd /home/.snapshots
```

**Step 2: Browse History**
Snapshots are numbered folders.

```bash
ls -l
# Example output: 1  2  3  4  5
```

Enter a snapshot folder (e.g., `5`) and navigate to your user directory.

```bash
# Path format: /home/.snapshots/<ID>/snapshot/<username>/
cd 5/snapshot/yourusername/
```

**Step 3: Restore Files**
Use the `cp` (copy) command to bring files back to your live home folder.

*Example: Restore a single file*

```bash
cp .bashrc /home/yourusername/
```

*Example: Restore a whole folder (recursive)*

```bash
cp -a Documents/ProjectX /home/yourusername/Documents/
```
