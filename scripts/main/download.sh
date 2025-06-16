#!/bin/sh
set -e

sudo pacman -Sy --noconfirm --needed git
git clone https://git.awdawd.eu/awd/ainstall /opt/ainstall
cd /opt/ainstall

./ainstall -S installArch -i sda