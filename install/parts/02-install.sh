#!/bin/sh

while getopts ":t:u:p:g:" opt; do
  case $opt in
    t) TIMEZONE=$OPTARG ;;
    u) USER=$OPTARG ;;
    p) PASS=$OPTARG ;;
    g) GRUBNAME=$OPTARG ;;
    :) echo "ERROR: Option '-$OPTARG' requires an argument" >&2; exit 1 ;;
    ?) echo "ERROR: Invalid option '-$OPTARG' (Valid: t, u, p, g)" >&2; exit 1 ;;
  esac
done

echo "Running script in new install"

ln -sf /usr/share/zoneinfo/${TIMEZONE} /etc/localtime
hwclock --systohc

locale-gen

groupadd sudo
groupadd wheel
useradd -m -G sudo -s /usr/bin/bash ${USER}
echo ${PASS} | passwd -s ${USER}

mkinitcpio -P
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=${GRUBNAME}
grub-mkconfig -o /boot/grub/grub.cfg

systemctl enable NetworkManager
