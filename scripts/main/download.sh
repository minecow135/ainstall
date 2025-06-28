#!/bin/sh
set -e

dir=/opt/ainstall

if [[ -e ${dir} ]]
then
  rm -r ${dir}
fi

sudo pacman -Sy --noconfirm --needed git
git clone https://git.awdawd.eu/awd/ainstall ${dir}
cd ${dir}

if [ ! -d ${dir}/logs ]
then
  mkdir -p ${dir}/logs
fi

touch ${dir}/logs/download.log

cat > ${dir}/logs/download.log <<EOF
downloaded: $(date)

dir: ${dir}
EOF

./ainstall -S installArch -i sda