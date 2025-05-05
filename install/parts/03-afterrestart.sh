#!/bin/sh

while getopts ":g:nl" opt; do
  case $opt in
    D) DOTFILEFOLDER=$OPTARG ;;
    n) NORESTART=1 ;;
    :) echo "ERROR: Option '-$OPTARG' requires an argument" >&2; exit 1 ;;
    ?) echo "ERROR: Invalid option '-$OPTARG' (Valid: g, n, l)" >&2; exit 1 ;;
  esac
done



if [[ -z ${NORESTART} ]]
then
  reboot
fi