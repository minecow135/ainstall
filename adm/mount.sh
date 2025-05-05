#!/bin/sh

while getopts ":i:c:p:f:" opt; do
  case $opt in
    i) drive=$OPTARG ;;
    c) cryptpass=$OPTARG ;;
    f) filesys=$OPTARG ;;
    :) echo "ERROR 821: Option '-$OPTARG' requires an argument" >&2; exit 821 ;;
    ?) echo "ERROR 820: Invalid option '-$OPTARG' (Valid: i, c, p, f)" >&2; exit 820 ;;
  esac
done

##################################### STATIC VARIABLES #####################################

MOUNT=/mnt/os

##################################### LOAD ENV FILE #####################################

if [[ ${env} ]]
then
  {
    source ${env}
  } || {
    echo "ERROR 831: Env file import failed" >&2; exit 831
  }
elif [[ $script ]]
then
  {
    source "./defaults.env"
  } || {
    echo "ERROR 830: Default env file import failed" >&2; exit 830
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
    echo "ERROR 850: Install drive not set (-i)" >&2; exit 850
  fi
fi

# Check if drive is valid

if [ ! $(ls /dev/${drive}) ]
then
  echo "ERROR 870: Install drive not valid (-i)" >&2; exit 870
fi

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
    echo "ERROR 856: Filesys not set (-f)" >&2; exit 856
  fi
fi

# Check if filesys valid

filesystems=(btrfs ext4)

##################################### SCRIPT #####################################

if [[ ${cryptpass} ]]
then
  echo -n "${cryptpass}" | cryptsetup luksOpen --batch-mode --key-file - /dev/${drive2} root
  drive2=mapper/root
fi

if [ ${filesys} = "btrfs" ]
then
  mount -m -o compress=zstd,subvol=@ /dev/${drive2} ${MOUNT}
  mount -m -o compress=zstd,subvol=@home /dev/${drive2} ${MOUNT}/home
  mount -m -o compress=zstd,subvol=@log /dev/${drive2} ${MOUNT}/var/log
  mount -m -o compress=zstd,subvol=@pkg /dev/${drive2} ${MOUNT}/var/cache/pacman/pkg
  mount -m -o compress=zstd,subvol=@.snapshots /dev/${drive2} ${MOUNT}/.snapshots
  mount -m -o compress=zstd,subvol=@swap /dev/${drive2} ${MOUNT}/swap
elif [ ${filesys} = "ext4" ]
then
  mount ${drive2} ${MOUNT}
fi

mount -m /dev/${drive}1 ${MOUNT}/boot

swapon ${MOUNT}/swap/swapfile

