# arch-linux-installation
I am reporting here all the steps for an Arch Linux installation.

sudo diskutil eraseDisk FAT32 ArchLinux /dev/disk4

https://gist.github.com/abelcallejo/846b9b21b35f401f8df733ffd78165ec

I follow this guide for the installation:
https://wiki.archlinux.org/title/Installation_guide

From this guide, I create a bootable installation media (SD card in my case).
https://wiki.archlinux.org/title/USB_flash_installation_medium

## Installation on my DELL XPS 13
localectl
loadkeys uk
ip link
iwctl
  device list
  station wlan0 connect Daniscarpa_5G
  .. digit passphrase ..
ping google.com
... OK ..
timedatectl set-timezone Europe/Oslo
fdisk -l


