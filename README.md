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


## Installation on my DELL XPS 13 (No encryption)

Change the keyboard to uk.
```
localectl
loadkeys uk
```

Connect to the Wifi. Mine is BetaOrix, from the names of my dogs :)
```
ip link
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

Create the 3 partitions, EFI, swap, linux sys.

p1: Linux swap. Not sure if this has to be the first, and how important it is, and how much this improves the performance. 
p2: EFI. Not sure if this is required. If I use a boot loader, it might be enough if I have a single partition. Also LVM can be used. Look into the difference, also if the fs matters.
p3: Linux root partition.
```
fdisk /dev/nvme0n1
  g

  n
  start sector: 4096
  last sector: +4G

  n
  last sector: +1G
  
  n
  all default

  t
  1
  19

  t
  2
  1

  t
  3
  23
  
  w
```

Create ext4 fs for the root partition.
```
mkfs.ext4 /dev/nvme0n1p3
```

Initialise the swap.
```
mkswap /dev/nvme0n1p1
```

Create the fs for the EFI partition.
```
mkfs.fat -F 32 /dev/nvme0n1p2
```

Mount the partitions and enable swap.
```
swapon /dev/nvme0n1p1
mount /dev/nvme0n1p3 /mnt
mount --mkdir /dev/nvme0n1p2 /mnt/boot
```

Install the packages base, linux kernel and firmware.
```
pacstrap -K /mnt base linux linux-firmware vim
```

Create the fstab file, the table of partitions with UUID, directory, fs type, fs check (0 disabled, 1 root, 2 other)
```
genfstab -U /mnt >> /mnt/etc/fstab
```

Chroot into the system.
```
arch-chroot /mnt
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
```

Install boot-loader (GRUB in my case).
```
pacman -Sy grub efibootmgr
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB --removable
```

Install iwd for Wifi connection.
```
pacman -Sy iwd
```

Set root password.
```
passwd
```

Remove the SD card.

Exit chroot and reboot.
```
exit
umount -R /mnt
reboot
```

Use your Arch Linux Machine <3 <3 <3






