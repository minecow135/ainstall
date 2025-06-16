#!/bin/sh
#set -e

while getopts ":r:t:u:p:Ng:" opt; do
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

if [[ -z ${autorun} ]]
then
  mv /home/${USER}/.bash_profile /home/${USER}/.bash_profile.bak
  cmd="sh ${scriptrundir}/ainstall.sh -r ${scriptrundir} -S"

  if [[ ${env} ]]
  then
    cmd+=" -E ${env}"
  fi

  cmd+=" installarchafter"

  if [[ ${norestart} ]]
  then
    cmd+=" -n"
  fi

  cat > /home/${USER}/.bash_profile <<EOF
#
# ~/.bash_profile
#

[[ -f ~/.bashrc ]] && . ~/.bashrc
${cmd}
EOF
  chown ${USER}:${USER} /home/${USER}/.bash_profile 
fi

mkinitcpio -P
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=${GRUBNAME}
grub-mkconfig -o /boot/grub/grub.cfg

systemctl enable NetworkManager
