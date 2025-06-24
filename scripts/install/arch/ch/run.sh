#!/bin/sh
#set -e

while getopts ":r:t:u:p:nNg:" opt; do
  case $opt in
    g) GRUBNAME=$OPTARG ;;
    t) TIMEZONE=$OPTARG ;;
    u) USER=$OPTARG ;;
    p) PASS=$OPTARG ;;
    n) norestart=true ;;
    N) autorun=true ;;
    :) echo "ERROR: Option '-$OPTARG' requires an argument" >&2; exit 1 ;;
    ?) echo "ERROR: Invalid option '-$OPTARG' (Valid: r, t, u, p, N, g)" >&2; exit 1 ;;
  esac
done

echo "Running script in new install"

ln -sf /usr/share/zoneinfo/${TIMEZONE} /etc/localtime
hwclock --systohc

locale-gen

if [[ ! $(getent group sudo) ]]
then
  groupadd sudo
fi 

if [[ ! $(getent group wheel) ]]
then
  groupadd wheel
fi 

useradd -m -G sudo -s /usr/bin/bash ${USER}
echo ${PASS} | passwd -s ${USER}

useradd -md ${scriptrundir}/home -G wheel -s /usr/bin/bash ainstall
passwd -d ainstall

chown -R ainstall:ainstall ${scriptrundir}

if [[ -z ${autorun} ]]
then
  mv ${scriptrundir}/home/.bash_profile ${scriptrundir}/home/.bash_profile.bak
  touch ${scriptrundir}/home/.bash_profile
  cmd="sh ${scriptrundir}/ainstall -r ${scriptrundir} -S"

  if [[ ${env} ]]
  then
    cmd+=" -E ${env}"
  fi

  cmd+=" installArchAfter"

  if [[ ${norestart} ]]
  then
    cmd+=" -n"
  fi

  cat > ${scriptrundir}/home/.bash_profile <<EOF
#
# ~/.bash_profile
#

[[ -f ~/.bashrc ]] && . ~/.bashrc
${cmd}
EOF
  chown ${USER}:${USER} /home/${USER}/.bash_profile 
  mkdir -p /etc/systemd/system/getty@tty1.service.d/
  touch /etc/systemd/system/getty@tty1.service.d/override.conf
  cat > /etc/systemd/system/getty@tty1.service.d/override.conf <<EOF
[Service]
ExecStart=
ExecStart=/usr/bin/agetty --autologin ainstall --noclear %I 38400 linux
Type=simple
EOF
else
  passwd -l ainstall
fi

mkinitcpio -P
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=${GRUBNAME}
grub-mkconfig -o /boot/grub/grub.cfg

systemctl enable NetworkManager
