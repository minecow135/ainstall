#!/bin/sh
set -e

while [ : ]; do
  case "$1" in
    -r | --scriptrundir)
      if [ $2 ]
      then
        scriptrundir=$2
        shift 2
      else
        echo "ERROR 5: Script directory missing" >&2; exit 5
      fi
      ;;
    -E | --env)
      if [ $2 ]
      then
        env=$(readlink -f $2)
        shift 2
      else
        echo "ERROR 6: env file missing" >&2; exit 6
      fi
      ;;
    -S | --script)
      script=true
      shift
      ;;
    *)
      break;
      ;;
  esac
done

##################################### STATIC VARIABLES #####################################

AINSTALL_VERSION=v0.1.0

##################################### GLOBAL SET VARIABLES #####################################

if [ ! ${AINSTALL_VERSION} ]
then
  echo "ERROR 125: aInstall version not found" >&2; exit 25
fi

MAJOR=$(echo $AINSTALL_VERSION | tr -d "v" | cut -d "." -f1)
MINOR=$(echo $AINSTALL_VERSION | tr -d "v" | cut -d "." -f2)
PATCH=$(echo $AINSTALL_VERSION | tr -d "v" | cut -d "." -f3)

##################################### LOAD ENV FILE #####################################

if [ ${env} ]
then
  {
    source ${env}
  } || {
    echo "ERROR 31: Env file import failed" >&2; exit 31
  }
elif [ $script ]
then
  if [ ${scriptrundir} ]
  then
    dir=${scriptrundir}
  else
    dir="/opt/ainstall"
  fi
  {
    source ${dir}/config/defaults.env
  } || {
    echo "ERROR 30: Default env file import failed" >&2; exit 30
  }
fi

##################################### GET USER INPUT #####################################



##################################### CHECK INPUTS, ENV-FILE #####################################

# Get scriptrundir

if [ -z ${scriptrundir} ]
then
  if [ ${ENV_INSTALL_SCRIPTRUNDIR} ]
  then
    scriptrundir=${ENV_INSTALL_SCRIPTRUNDIR}
  elif [ -z ${script} ]
  then
    echo "INPUT scriptrundir"
  else
    echo "ERROR 59: Script run directory not set (-r)" >&2; exit 59
  fi
fi

# Check if scriptrundir exists

if [ -d ${scriptrundir} ]
then
  scriptrundir=$(readlink -f ${scriptrundir})
else
  echo "ERROR 79: Script run directory not found (-r)" >&2; exit 79
fi

##################################### RUN SCRIPT PART #####################################

if [ ! $1 ]
then
  echo "ERROR 90: Command part not set" >&2; exit 90
fi

part=$1
shift

export AINSTALL_VERSION scriptrundir script env

case ${part} in
  "installArch")
    sh ${scriptrundir}/scripts/install/arch/run.sh $@
    ;;
  "installArchCh")
    sh ${scriptrundir}/scripts/install/arch/ch/run.sh $@
    ;;
  "installArchAfter")
    sh ${scriptrundir}/scripts/install/arch/after/run.sh $@
    ;;

  "appInstall")
    sh ${scriptrundir}/scripts/appinstall/run.sh $@
    ;;
    
  "mount")
    sh ${scriptrundir}/scripts/adm/mount.sh $@
    ;;
  *)
    echo "ERROR 95: Command part invalid" >&2; exit 95
    ;;
esac
