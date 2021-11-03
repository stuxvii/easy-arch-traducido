[![Build Status](https://img.shields.io/endpoint.svg?url=https%3A%2F%2Factions-badge.atrox.dev%2Fclassy-giraffe%2Feasy-arch%2Fbadge%3Fref%3Dmain&style=flat)](https://actions-badge.atrox.dev/classy-giraffe/easy-arch/goto?ref=main)
![](https://img.shields.io/github/license/classy-giraffe/easy-arch)

### Introduction
[easy-arch](https://github.com/classy-giraffe/easy-arch) is a **script** made in order to boostrap a basic **Arch Linux** environment with **BTRFS snapshots** and **encryption** by using a fully automated process (UEFI only).

### How does it work?
1. Download an Arch Linux ISO from [here](https://archlinux.org/download/)
2. Flash the ISO onto an [USB Flash Drive](https://wiki.archlinux.org/index.php/USB_flash_installation_medium).
3. Boot the live environment
4. Set the keyboard layout by using `loadkeys <kblayout>`
5. Connect to the internet
6. Run this `bash <(curl -sL bit.ly/easy-arch)`

### Partitions layout 

| Partition Number | Label     | Size              | Mountpoint     | Filesystem              |
|------------------|-----------|-------------------|----------------|-------------------------|
| 1                | ESP       | 512 MiB           | /boot/         | FAT32                   |
| 2                | Cryptroot | Rest of the disk  | /              | BTRFS Encrypted (LUKS2) |

The **partitions layout** is simple and it's inspired by [this section](https://wiki.archlinux.org/index.php/Dm-crypt/Encrypting_an_entire_system#Btrfs_subvolumes_with_swap) of the Arch Linux Wiki. As you can see there're only two partitions:
1. A **FAT32**, 512MiB sized, mounted at `/boot/efi` for the ESP.
2. A **LUKS2 encrypted container**, which takes the rest of the disk space, mounted at `/` for the rootfs.

### BTRFS subvolumes layout

| Subvolume Number | Subvolume Name | Mountpoint       |
|------------------|----------------|------------------|
| 1                | @              | /                |
| 2                | @home          | /home            |
| 3                | @snapshots     | /.snapshots      |
| 4                | @var_log       | /var/log         |

The **BTRFS subvolumes layout** follows the traditional and suggested layout used by **Snapper**, you can find it [here](https://wiki.archlinux.org/index.php/Snapper#Suggested_filesystem_layout). Here's a brief explanation of the **BTRFS layout** I chose:
1. `@` mounted at `/`.
2. `@home` mounted at `/home`.
3. `@snapshots` mounted at `/.snapshots`.
4. `@var_log` mounted at `/var/log`.
