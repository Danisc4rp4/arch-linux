# Arch Linux Installation Guide

I follow [this guide](https://gist.github.com/abelcallejo/846b9b21b35f401f8df733ffd78165ec) for the creation of the SD card.
I follow [this guide](https://wiki.archlinux.org/title/Installation_guide) for the installation.


## Create the bootable SD card

Dowload the linux iso image from [here](https://archlinux.org/download/).

Convert the iso image into img.dmg .
```
hdiutil convert -format UDRW -o linux.img linux.iso
```

If you get "hdiutil: convert failed - Resource temporarily unavailable" then:
```
hdiutil info
hdiutil detach /dev/diskN
```

Find your SD card
```
diskutil list
diskutil info /dev/disk4
```

Format
```
sudo diskutil eraseDisk FAT32 ArchLinux /dev/disk4
```

Insert the SD card and umount it.
```
diskutil unmountDisk /dev/disk4
```

Write the image into the SD card.
```
time sudo dd if=archlinux-2026.03.01-x86_64.img.dmg of=/dev/rdisk4 bs=1m status=progress
```


## Installation on my DELL XPS 13 (With encryption)

Instructions for Dell XPS
- Press F12 when before the Dell logo at startup.
- Enter BIOS setup
- Enable miscellaneus devices - SDD boot
- Restart and boot from SSD
- You can start installation below.

Change the keyboard to uk.
```
localectl
loadkeys uk
```

Connect to the Wifi. Mine is BetaOrix, from the names of my dogs :)
```
ip link
ip link wlan0 up
iwctl

  device list
  station wlan0 connect BetaOrix5G
  .. digit passphrase ..
  exit
  
ping google.com
... OK ..
```

Once the connection to the internet is established, check if the system is synced by the service systemd-timesyncd automatically.
```
systemctl status systemd-timesyncd
timedatectl
```

Set timezone and verify changes.
```
timedatectl set-timezone Europe/Oslo
timedatectl
```

List the disk partitions.
```
fdisk -l
fdisk -l /dev/nvme0n1
```

Check the best sector size and set it up (4096 in my case).
```
nvme id-ns -H /dev/nvme0n1 | grep "Relative Performance"
nvme format --lbaf=1 /dev/nvme0n1
```

Create the partitions

Since we now want to introduce encryption, the best way is to include Swap and root into the same partition encrypted once. The first sector must start with your disk sector size to avoid disallignment (mine is 4096). For p2 I want to use btrfs instead of LVM because I want to use minikube in my local machine and I want dynamic sizes for virtual volumes.
```
fdisk /dev/nvme0n1
  g

  n
  1
  start sector: 4096
  last sector: +1G

  n
  all default

  t
  1
  1

  t
  2
  20
  
  w
```

Encryption
```
cryptsetup luksFormat --type luks2 /dev/nvme0n1p2
```
Type your password twice.

Open the vault
```
cryptsetup open /dev/nvme0n1p2 cryptbtrfs
```
You can view cryptlvm vault in /dev/mapper (ls).

Create physical volume, volume group and logical volumes
```
mkfs.btrfs -L ARCH /dev/mapper/cryptbtrfs
mount /dev/mapper/cryptbtrfs /mnt
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@log
btrfs subvolume create /mnt/@pkg
umount /mnt
```

Mount all
```
mount -o compress=zstd,subvol=@ /dev/mapper/cryptlvm /mnt

mkdir -p /mnt/{home,var/log,var/cache/pacman/pkg,boot}
mount -o compress=zstd,subvol=@home /dev/mapper/cryptlvm /mnt/home
mount -o compress=zstd,subvol=@log /dev/mapper/cryptlvm /mnt/var/log
mount -o compress=zstd,subvol=@pkg /dev/mapper/cryptlvm /mnt/var/cache/pacman/pkg

mkfs.fat -F 32 /dev/nvme0n1p1
mount /dev/nvme0n1p1 /mnt/boot
```

Before pacstrap create /etc/vconsole.conf in chroot
```
arch-chroot /mnt
echo "KEYMAP=uk" > /etc/vconsole.conf
exit
```

Install the packages base, linux kernel and firmware.
```
pacstrap -K /mnt base linux linux-firmware btrfs-progs intel-ucode vim networkmanager compsize
```

Create the fstab file, the table of partitions with UUID, directory, fs type, fs check (0 disabled, 1 root, 2 other)
```
genfstab -U /mnt >> /mnt/etc/fstab
```

Chroot into the system.
```
arch-chroot /mnt
```

Create the swap file
```
btrfs filesystem mkswapfile --size 16G /swapfile
swapon /swapfile
exit
```

Generate fstab
```
genfstab -U /mnt >> /mnt/etc/fstab
cat /mnt/etc/fstab
```
If entries are duplicated, than you can safely override
```
genfstab -U /mnt > /mnt/etc/fstab
cat /mnt/etc/fstab
```
Last line must be /swapfile

Chroot again and setup mkinitcpio
```
arch-chroot /mnt
vim /etc/mkinitcpio.conf
... Change HUKS HOOKS=(base systemd autodetect microcode modconf kms sd-vconsole keyboard sd-encrypt block filesystems btrfs).. save
mkinitcpio -P
```

Set the system time.
```
ln -sf /usr/share/zoneinfo/Europe/Oslo /etc/localtime
```

Syncronise the hardware clock with the system clock.
```
hwclock --systohc
```

To prevent clock drift and ensure accurate time, set up time synchronization using a Network Time Protocol (NTP) client.
```
systemctl enable systemd-timesyncd
```

Decomment the locale for the language English British and generate the locales.
```
sed -i "s/#en_GB.UTF/en_GB.UTF/g" /etc/locale.gen
```
You can also edit the file using vim.

Generate the locales.
```
locale-gen
```

Create the locale.conf(5) file, and set the LANG variable (you can use vim).
```
echo "LANG=en_GB.UTF-8" > /etc/locale.conf
```

Make the change of the keyboard layout persistent, editing the vconsole.conf file (you can use vim).
```
echo "KEYMAP=uk" > /etc/vconsole.conf
```

Create the hostname file and set your hostname (you can use vim).
```
echo "xps" > /etc/hostname
```

Enable the services for networking.
```
systemctl enable systemd-resolved
systemctl enable systemd-networkd
ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
cat <<EOF > /etc/systemd/network/25-wireless.network
[Match]
Name=wlan*

[Network]
DHCP=yes
IgnoreCarrierLoss=3s
EOF

systemctl restart systemd-resolved
systemctl restart systemd-networkd

pacman -Sy iwd
mkdir -p /etc/iwd
cat <<EOF > /etc/iwd/main.conf
[General]
EnableNetworkConfiguration=false
EOF
systemctl enable iwd
```

Install boot-loader systemd-boot
```
bootctl install
vim /boot/loader/loader.conf
... content:
default  arch.conf
timeout  3
console-mode max
editor   no
... save
blkid -s UUID -o value /dev/nvme0n1p2
vim /boot/loader/entries/arch.conf
... content
title   Arch Linux
linux   /vmlinuz-linux
initrd  /intel-ucode.img
initrd  /initramfs-linux.img
options rd.luks.name=UUID_OF_LUKS_PARTITION=cryptbtrfs root=/dev/mapper/cryptbtrfs rootflags=subvol=@ rw
... save
```

Set root password.
```
passwd
sync
exit
umount -R /mnt
cryptsetup close cryptbtrfs
```

Remove the SD card.

Reboot.
```
reboot
```

Use your Arch Linux Machine <3 <3 <3

Decrypt your drive and login with root.

Clone this repo and use the scripts to carry on the installation
```
pacman -S git base-devel openssh
ssh-keygen -t ed25519 -C "daniscarpa8593@gmail.com"

# 1. Install it
pacman -S github-cli

gh auth login
... authenticate using browser, but do it from a different device with the given code at github.com/login/device ...
git config --global user.name "Dani"
git config --global user.email "daniscarpa8593@gmail.com"
ssh-keyscan -t ed25519 github.com >> ~/.ssh/known_hosts
git clone git@github.com:Danisc4rp4/arch-linux.git
cd arch-linux
ssh-agent -s
ssh-add ~/.ssh/id_ed25519
```

Run script 00-setup-user.sh
```
chmode +x *.sh
sh 00-setup-user.sh
```




