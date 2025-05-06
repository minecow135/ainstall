#!/bin/sh
set -e

while getopts ":i:g:h:k:l:t:c:f:u:p:r:s:nd:D:SE:" opt; do
  case $opt in
    i) drive=$OPTARG ;;
    g) grubname=$OPTARG ;;
    h) hostname=$OPTARG ;;
    k) keymap=$OPTARG ;;
    l) lang=$OPTARG ;;
    t) timezone=$OPTARG ;;
    c) cryptpass=$OPTARG ;;
    f) filesys=$OPTARG ;;
    u) user=$OPTARG ;;
    p) pass=$OPTARG ;;
    r) scriptrundir=$OPTARG ;;
    s) scriptdir=$OPTARG ;;
    n) norestart=true ;;
    d) dotfilegit=$OPTARG ;;
    D) dotfilefolder=$OPTARG ;;
    S) script=true ;;
    E) env=$OPTARG ;;
    :) echo "ERROR 121: Option '-$OPTARG' requires an argument" >&2; exit 121 ;;
    ?) echo "ERROR 120: Invalid option '-$OPTARG' (Valid: g, h, k, l, t, c, f, u, p, r, s, n, d, D, S, E)" >&2; exit 120 ;;
  esac
done

##################################### STATIC VARIABLES #####################################

MOUNT=/mnt/os
AINSTALL_VERSION=v0.1.0

##################################### GLOBAL SET VARIABLES #####################################

MAJOR=$(echo $AINSTALL_VERSION | tr -d "v" | cut -d "." -f1)
MINOR=$(echo $AINSTALL_VERSION | tr -d "v" | cut -d "." -f2)
PATCH=$(echo $AINSTALL_VERSION | tr -d "v" | cut -d "." -f3)

##################################### INSTALL DEPENDENCIES #####################################

if [[ -z ${script} ]]
then
  pacman -S --noconfirm --needed --quiet dialog
fi

##################################### LOAD ENV FILE #####################################

if [[ ${env} ]]
then
  {
    source ${env}
  } || {
    echo "ERROR 131: Env file import failed" >&2; exit 131
  }
elif [[ $script ]]
then
  {
    source "./defaults.env"
  } || {
    echo "ERROR 130: Default env file import failed" >&2; exit 130
  }
fi

##################################### GET USER INPUT #####################################



##################################### CHECK INPUTS, ENV-FILE #####################################

# Get drive

if [[ -z ${drive} ]]
then
  if [[ ${ENV_DRIVE} ]]
  then
    drive=${ENV_DRIVE}
  elif [[ -z ${script} ]]
  then
    drives=$(lsblk --exclude 254 --nodeps --noheadings --output NAME)
    echo "INPUT drive"
  else
    echo "ERROR 150: Install drive not set (-i)" >&2; exit 150
  fi
fi

# Check if drive is valid

if [ ! $(ls /dev/${drive}) ]
then
  echo "ERROR 170: Install drive not valid (-i)" >&2; exit 170
fi

# Get grubname

if [[ -z ${grubname} ]]
then
  if [[ ${ENV_GRUBNAME} ]]
  then
    grubname=${ENV_GRUBNAME}
  elif [[ -z ${script} ]]
  then
    echo "INPUT grubname"
  else
    echo "ERROR 151: Grub name not set (-g)" >&2; exit 151
  fi
fi

# Get hostname

if [[ -z ${hostname} ]]
then
  if [[ ${ENV_HOSTNAME} ]]
  then
    hostname=${ENV_HOSTNAME}
  elif [[ -z ${script} ]]
  then
    echo "INPUT hostname"
  else
    echo "ERROR 152: Hostname not set (-h)" >&2; exit 152
  fi
fi

# Get keymap

if [[ -z ${keymap} ]]
then
  if [[ ${ENV_KEYMAP} ]]
  then
    keymap=${ENV_KEYMAP}
  elif [[ -z ${script} ]]
  then
    echo "INPUT keymap"
  else
    echo "ERROR 153: Keymap not set (-k)" >&2; exit 153
  fi
fi

# Check if keymap valid

if [ ! $(localectl list-keymaps | grep -ix ${keymap}) ]
then
  echo "ERROR 173: Keymap not valid (-k)" >&2; exit 173
fi

keymap=$(localectl list-keymaps | grep -ix ${keymap})

# Get lang

if [[ -z ${lang} ]]
then
  if [[ ${ENV_LANG} ]]
  then
    lang=${ENV_LANG}
  elif [[ -z ${script} ]]
  then
    echo "INPUT lang"
  else
    echo "ERROR 154: Language not set (-l)" >&2; exit 154
  fi
fi

# Check if language valid

if [ ! $(cat /etc/locale.gen | cut -d ' ' -f1 | tr -d '#' | grep -i "^${lang}$") ]
then
  echo "ERROR 174: Language not valid (-l)" >&2; exit 174
fi

lang=$(cat /etc/locale.gen | cut -d ' ' -f1 | tr -d '#' | grep -i "^${lang}$")

# Get timezone

if [[ -z ${timezone} ]]
then
  if [[ ${ENV_TIMEZONE} ]]
  then
    timezone=${ENV_TIMEZONE}
  elif [[ -z ${script} ]]
  then
    echo "INPUT timezone"
  else
    echo "ERROR 155: Timezone not set (-t)" >&2; exit 155
  fi
fi

# Check if timezone valid

if [ ! $(timedatectl list-timezones | grep -ix ${timezone}) ]
then
  echo "ERROR 175: Timezone not valid (-t)" >&2; exit 175
fi

timezone=$(timedatectl list-timezones | grep -ix ${timezone})

# Get cryptpass

if [[ -z ${cryptpass} ]]
then
  if [[ ${ENV_CRYPTPASS} ]]
  then
    cryptpass=${ENV_CRYPTPASS}
  elif [[ -z ${script} ]]
  then
    echo "INPUT cryptpass"
  fi
fi

# Get filesys

if [[ -z ${filesys} ]]
then
  if [[ ${ENV_FILESYS} ]]
  then
    filesys=${ENV_FILESYS}
  elif [[ -z ${script} ]]
  then
    echo "INPUT filesys"
  else
    echo "ERROR 156: Filesys not set (-f)" >&2; exit 156
  fi
fi

# Check if filesys valid

filesystems=(btrfs ext4)

# Make all characters lowercase
filesys=$(echo "$filesys" | tr '[:upper:]' '[:lower:]')

if [[ ! ${filesystems[*]} =~ (^|[[:space:]])"$filesys"($|[[:space:]]) ]];
then
  echo "ERROR 176: Filesys not valid (-f)" >&2; exit 176
fi

# Get user

if [[ -z ${user} ]]
then
  if [[ ${ENV_USER} ]]
  then
    user=${ENV_USER}
  elif [[ -z ${script} ]]
  then
    echo "INPUT user"
  else
    echo "ERROR 157: Username not set (-u)" >&2; exit 157
  fi
fi

# Get pass

if [[ -z ${pass} ]]
then
  if [[ ${ENV_PASS} ]]
  then
    pass=${ENV_PASS}
  elif [[ -z ${script} ]]
  then
    echo "INPUT pass"
  else
    echo "ERROR 158: Password not set (-p)" >&2; exit 158
  fi
fi

# Get scriptrundir

if [[ -z ${scriptrundir} ]]
then
  if [[ ${ENV_SCRIPTRUNDIR} ]]
  then
    scriptrundir=${ENV_SCRIPTRUNDIR}
  elif [[ -z ${script} ]]
  then
    echo "INPUT scriptrundir"
  else
    echo "ERROR 159: Script run directory not set (-r)" >&2; exit 159
  fi
fi

# Check if scriptrundir exists

if [[ ! -d ${scriptrundir} ]]
then
  echo "ERROR 179: Script run directory not found (-r)" >&2; exit 179
fi

# Get scriptdir

if [[ -z ${scriptdir} ]]
then
  if [[ ${ENV_SCRIPTDIR} ]]
  then
    scriptdir=${ENV_SCRIPTDIR}
  elif [[ -z ${script} ]]
  then
    echo "INPUT scriptdir"
  else
    echo "ERROR 160: Script directory not set (-s)" >&2; exit 160
  fi
fi

# Check if scriptdir valid

if [[ ! $scriptdir =~ ^/. ]]
then
  echo "ERROR 170: Script directory not valid (-s)" >&2; exit 170
fi

# Get norestart

if [[ -z ${norestart} ]]
then
  if [[ ${ENV_NORESTART} ]]
  then
    norestart=${ENV_NORESTART}
  elif [[ -z ${script} ]]
  then
    echo "INPUT norestart"
  fi
fi

# Get dotfilegit

if [[ -z ${dotfilegit} ]]
then
  if [[ ${ENV_DOTFILEGIT} ]]
  then
    dotfilegit=${ENV_DOTFILEGIT}
  elif [[ -z ${script} ]]
  then
    if [[ -z ${dotfilefolder} ]]
    then
      if [[ ${ENV_DOTFILEFOLDER} ]]
      then
        dotfilefolder=${ENV_DOTFILEFOLDER}
      else
        echo "INPUT dotfilegit"
        echo "INPUT dotfilefolder"
      fi
    fi
  fi
fi

# Check if dotfiles valid

if [ ${dotfilegit} ]
then
  {
    folder=./dots/
    rm -r ${folder}
    echo "cloning dotfiles"
    git clone --quiet ${dotfilegit} ${folder}
    dotfilefolder=${folder}
  } || {
    echo "ERROR 180: Dotfile link not valid (-d)" >&2; exit 180
  }
fi

if [ ${dotfilefolder} ]
then
  if [ ! -d $dotfilefolder ]
  then
    echo "ERROR 182: Dotfile folder not found (-d/-D)" >&2; exit 182
  else
    if [ ! -e ${dotfilefolder}/AINSTALL ] || ! source ${dotfilefolder}/AINSTALL
    then
      echo "ERROR 183: Dotfile folder not valid (-d/-D)" >&2; exit 183
    else
      if [ ! $AINSTALL_VERSION_NEEDED ]
      then
        echo "ERROR 184: Needed aInstall version not specified" >&2; exit 184
      else
        dotfile_major=$(echo $AINSTALL_VERSION_NEEDED | tr -d "v" | cut -d "." -f1)
        dotfile_minor=$(echo $AINSTALL_VERSION_NEEDED | tr -d "v" | cut -d "." -f2)
        dotfile_patch=$(echo $AINSTALL_VERSION_NEEDED | tr -d "v" | cut -d "." -f3)

        if [ ${MAJOR} -lt ${dotfile_major} ]
        then
          echo "ERROR 186: Dotfiles need newer aInstall script (major)" >&2; exit 186
        elif [ ${MAJOR} -eq ${dotfile_major} ] && [ ${MINOR} -lt ${dotfile_minor} ]
        then
          echo "ERROR 187: Dotfiles need newer aInstall script (minor)" >&2; exit 187
        elif [ ${MAJOR} -eq ${dotfile_major} ] && [ ${MINOR} -eq ${dotfile_minor} ] && [ ${PATCH} -lt ${dotfile_patch} ]
        then
          echo "ERROR 188: Dotfiles need newer aInstall script (patch)" >&2; exit 188
        fi
      fi
    fi
  fi
fi

##################################### SCRIPT #####################################

loadkeys ${keymap}

# clear old partitions
swapoff ${MOUNT}/swap/swapfile
umount -R ${MOUNT}
cryptsetup close /dev/mapper/root
wipefs --force --all /dev/${drive}

# get pc details
swapsize=$(awk '/MemTotal/ {print int($2/1000000+0.5)*2}' /proc/meminfo)

blockdev --getss /dev/${drive}
blockdev --getsz /dev/${drive}

sfdisk --force --wipe always /dev/${drive} < ${scriptrundir}/install/parts/disk

drive2=${drive}2

if [ ${cryptpass} ]
then
  echo -n "${cryptpass}" | cryptsetup luksFormat --batch-mode --key-file - /dev/${drive}2
  echo -n "${cryptpass}" | cryptsetup luksOpen --batch-mode --key-file - /dev/${drive}2 root
  drive2=mapper/root
fi

mkfs.fat -F 32 /dev/${drive}1

if [[ ${filesys} = "btrfs" ]]
then
  mkfs.btrfs -f /dev/${drive2}

  mount -m /dev/${drive2} ${MOUNT}

  btrfs subvolume create ${MOUNT}/@
  btrfs subvolume create ${MOUNT}/@home
  btrfs subvolume create ${MOUNT}/@log
  btrfs subvolume create ${MOUNT}/@pkg
  btrfs subvolume create ${MOUNT}/@.snapshots
  btrfs subvolume create ${MOUNT}/@swap

  umount ${MOUNT}

  mount -m -o compress=zstd,subvol=@ /dev/${drive2} ${MOUNT}
  mount -m -o compress=zstd,subvol=@home /dev/${drive2} ${MOUNT}/home
  mount -m -o compress=zstd,subvol=@log /dev/${drive2} ${MOUNT}/var/log
  mount -m -o compress=zstd,subvol=@pkg /dev/${drive2} ${MOUNT}/var/cache/pacman/pkg
  mount -m -o compress=zstd,subvol=@.snapshots /dev/${drive2} ${MOUNT}/.snapshots
  mount -m -o compress=zstd,subvol=@swap /dev/${drive2} ${MOUNT}/swap

  btrfs filesystem mkswapfile --size ${swapsize}g --uuid clear ${MOUNT}/swap/swapfile
elif [[ ${filesys} = "ext4" ]]
then
  mkfs.ext4 ${drive2}

  mount ${drive2} ${MOUNT}

  mkswap -U clear --size ${swapsize}G --file ${MOUNT}/swap/swapfile
fi

mount -m /dev/${drive}1 ${MOUNT}/boot

swapon ${MOUNT}/swap/swapfile

pacstrap -K ${MOUNT} base linux linux-firmware grub efibootmgr networkmanager sudo

genfstab -U ${MOUNT} >> ${MOUNT}/etc/fstab

sed -i "s/#${lang}/${lang}/" ${MOUNT}/etc/locale.gen
echo LANG=${lang} > ${MOUNT}/etc/locale.conf
echo KEYMAP=${keymap} > ${MOUNT}/etc/vconsole.conf

echo ${hostname} > ${MOUNT}/etc/hostname
cat >>${MOUNT}/etc/hosts <<EOF

127.0.0.1 localhost
::1 localhost
127.0.0.1 ${hostname}
EOF

if [ ${cryptpass} ]
then
  # get disk uuid
  driveuuid=$(blkid /dev/${drive}2 -o export | awk '/^UUID/ {print $1}' | cut -d = -f2)

  sed -i '/^HOOKS=(/s/filesystems/encrypt filesystems/' ${MOUNT}/etc/mkinitcpio.conf
  sed -i "s/GRUB_CMDLINE_LINUX=\"/GRUB_CMDLINE_LINUX=\"cryptdevice=\/dev\/disk\/by-uuid\/${driveuuid}:root root=\/dev\/mapper\/root /" ${MOUNT}/etc/default/grub
fi

sed -i '/GRUB_DISABLE_OS_PROBER=/c\GRUB_DISABLE_OS_PROBER=false' ${MOUNT}/etc/default/grub

sed -i '/%sudo	ALL=(ALL:ALL) ALL/c\%sudo ALL=(ALL:ALL) ALL' ${MOUNT}/etc/sudoers
sed -i '/%wheel	ALL=(ALL:ALL) NOPASSWD: ALL/c\%wheel ALL=(ALL:ALL) NOPASSWD: ALL' ${MOUNT}/etc/sudoers

cp -r ${scriptrundir} ${MOUNT}/${scriptdir}
arch-chroot ${MOUNT} sh ${scriptdir}/install/parts/02-install.sh -u ${user} -p ${pass} -g ${grubname} -t ${timezone}

if [ ${dotfilegit} ]
then
  echo "Dotfile git: ${dotfilegit}"
elif [ ${dotfilefolder} ]
then
  echo "Dotfile folder: ${dotfilefolder}"
fi

if [[ -z ${norestart} ]]
then
  reboot
fi

