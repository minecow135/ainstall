#!/bin/sh
set -e

while getopts ":n" opt; do
  case $opt in
    n) NORESTART=1 ;;
    :) echo "ERROR 221: Option '-$OPTARG' requires an argument" >&2; exit 221 ;;
    ?) echo "ERROR 220: Invalid option '-$OPTARG' (Valid: n)" >&2; exit 220 ;;
  esac
done

echo "AAAAAAAAAA"
sleep 3

sudo rm -f /etc/systemd/system/getty@tty1.service.d/override.conf
sudo passwd -l ainstall

if [[ -z ${NORESTART} ]]
then
  reboot
fi
