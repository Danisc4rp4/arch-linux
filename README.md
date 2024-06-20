# Arch Linux Installation Guide

I follow [this guide](https://gist.github.com/abelcallejo/846b9b21b35f401f8df733ffd78165ec) for the creation of the SD card.
I follow [this guide](https://wiki.archlinux.org/title/Installation_guide) for the installation.


## Create the bootable SD card

Format the SD card 
```
sudo diskutil eraseDisk FAT32 ArchLinux /dev/disk4

```


## Installation on my DELL XPS 13

Change the keyboard to uk.
```
localectl
loadkeys uk
```

Check the network devices names.
```
ip link
iwctl

  device list
  station wlan0 connect Daniscarpa_5G
  .. digit passphrase ..
  
ping google.com
... OK ..
```

Set the timezone to Oslo.
```
timedatectl set-timezone Europe/Oslo
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
p1: Linux swap
p2: EFI
p3: Linux root
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
mount --mkdir /dev/nvme0n1p2 /mnt/boot
mount /dev/nvme0n1p3 /mnt
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
sed -I "s/#en_GB.UTF/en_GB.UTF/g" /etc/locale.gen
locale-gen
```

Create the locale.conf(5) file, and set the LANG variable.
```
/etc/locale.conf
LANG=en_GB.UTF-8
```

Make the change of the keyboard layout persistent, editing the vconsole.conf file.
```
echo "KEYMAP=uk" > /etc/vconsole.conf
```

Create the hostname file and set your hostname.
```
echo "xps" >> /etc/hostname
```

Enable the services for networking.
```
systemctl enable sysyemd-resolved
systemctl enable sysyemd-networkd
```




