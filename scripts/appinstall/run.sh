#!/bin/bash
set -e

os=$(uname)
DOTFILEDEST=${scriptrundir}/dots/${USER}/

installFiles() {
  installOS=$1

  for file in $(ls ${DOTFILEDEST}/packages | grep .*\.json$)
  do
    osAndGlobal ${installOS} ${file}
  done
}

osAndGlobal() {
  installOS=$1
  file=$2

  data=$(jq --arg installOS ${installOS} ' {
    package: (.global.package + .[$ARGS.named.installOS].package),
    git: (.global.git + .[$ARGS.named.installOS].git),
    yay: (.global.yay + .[$ARGS.named.installOS].yay),
    cmd: (.global.cmd + .[$ARGS.named.installOS].cmd),
    flatpak: (.global.flatpak + .[$ARGS.named.installOS].flatpak)
  } ' "${DOTFILEDEST}/packages/${file}")

  if [ "${data}" ]
  then
    packageTypes "${installOS}" "${data}"
  fi
}

packageTypes() {
  installOS=$1
  data=$2

  echo ${data} | jq -cr '.|keys_unsorted[]' | while read key
  do
    input=$(echo ${data} | jq --arg key "${key}" -c '.[$ARGS.named.key]')
    if [ "${input}" ] && [ "${input}" != "null" ]
    then
      echo ${data} | jq -cr ".${key}[]" | while read package
      do
        install${key} "${installOS}" "${package}"
      done
    fi
  done
}

installpackage() {
  installOS=$1
  package=$2

  case "${installOS}" in
    "arch")
      echo run: sudo pacman -S --noconfirm --needed ${package}
    ;;
    "debian")
      echo run: sudo apt install -y ${package}
    ;;
    *)
      echo "ERROR"
    ;;
  esac
}

installgit() {
  installOS=$1
  package=$2

  repo=$(echo ${package} | jq -cr '.repo')

  if [ "${repo}" ] && [ "${repo}" != null ]
  then
    echo run: git clone ${repo} LOCATION

    install=$(echo ${package} | jq -cr '.install')
    if [ "${install}" ] && [ "${install}" != null ]
    then
      dir=$PWD
      echo run: cd LOCATION
      echo run: ${install}
      echo run: cd ${dir}
    fi
  fi

}

installyay() {
  installOS=$1
  package=$2

  echo run: yay -S --answerdiff None --answerclean None --removemake --noconfirm $package
}

installcmd() {
  installOS=$1
  package=$2

  echo run: $package
}

installflatpak() {
  installOS=$1
  package=$2

  repo=$(echo ${package} | jq -cr '.repo')
  app=$(echo ${package} | jq -cr '.app')

  if [ "${repo}" ] && [ "${app}" ] && [ "${repo}" != null ] && [ "${app}" != null ]
  then
    echo run: flatpak install -uy ${repo} ${app}
  fi 
}

if [ "$os" = "Linux" ]; then
  if [ -f /etc/arch-release ]
  then
    currentOS="arch"
  elif [ -f /etc/debian_version ]
  then
    currentOS="debian"
  #elif [ -f /etc/redhat-release ]
  #then
  #  redhat
  else
    echo "ERROR xxx: distro not supported" >&2; exit 999
  fi
# macOS
#elif [ "$os" = "Darwin" ]
#then
else
echo "ERROR xxx: OS not supported" >&2; exit 999
fi

installFiles ${currentOS}
