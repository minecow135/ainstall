#!/bin/sh
set -e

dir=/opt/ainstall

sudo pacman -Sy --noconfirm --needed git
git clone https://git.awdawd.eu/awd/ainstall ${dir}
cd ${dir}

./ainstall -S installArch -i sda