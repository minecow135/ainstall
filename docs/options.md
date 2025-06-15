# Options

## Main

- -r | --scriptrundir
  
  Set where the script is saved, ot where it should be downloaded to

- -E | --env
  
  Set environment file with options to use

- -S | --script
  
  Enable automatic install without any confirm.

  ### WARNING: THIS WILL RUN THE SCRIPT WITH NO CONFIRMATION. MAKE SURE TO DOUBLE CHECK EVRY INPUT

## Arch install

- -i

  Set drive to install arch linux to

- -b
  
  Set the size of the boot partition

- -g

  Set grub name. This is what the boot option is called

- -h

  Set hostname for the finished installation

- -k

  Set keyboard layout for the finished installation

- -l

  Set language for the finished installation

- -t

  Set timezone for the finished installation

- -c

  Set password for encrypted drive for the finished installation

- -f

  Set filesystem for the main partition

  ### Valid options

  - btrfs
  - ext4

- -u

  Set username for the default user

- -p

  Set password for the default user

- -s

  Set where the script should be saved on the finished installation

- -n

  Disable automatic restart after finised install

- -N
  
  Disable automatic script run after restart

- -d

  Set dotfile git repository to download

- -D

  Set folder for local dotfiles

## Arch install after restart

- -n

  Disable automatic restart after finised install

## Mount

- -i

  Set the drive to mount

- -c

  Set password used for encrypted drive

- -f

  Set filesystem used for the main partition
