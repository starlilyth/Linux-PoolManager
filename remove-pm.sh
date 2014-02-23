#!/bin/bash

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi
echo -e "This script will REMOVE the IFMI PoolManager web interface.\n"
echo -e "It will not undo the Apache security changes.\n"
read -p "Are you sure?(y/n)" input
shopt -s nocasematch
case "$input" in
  y|Y|Yes)
  if [ ! -e /var/www/IFMI ]; then
          echo "IFMI not installed"
          exit 1 ;
  else
    mv /var/www/favicon.ico /var/www/IFMI/favicon.ico
#    mv /var/www/bamt/mgpumon.css /var/www/IFMI/mgpumon.css.ifmi
#    mv /var/www/bamt/mgpumon.css.bamt /var/www/bamt/mgpumon.css
    mv /usr/lib/cgi-bin/status.pl /var/www/IFMI/status.pl.ifmi
    mv /usr/lib/cgi-bin/status.pl.pre-ifmi /usr/lib/cgi-bin/status.pl
    mv /usr/lib/cgi-bin/confedit.pl /var/www/IFMI/
    mv /usr/lib/cgi-bin/poolmanage.pl /var/www/IFMI/
    mv /etc/sudoers /etc/sudoers.ifmi
    mv /etc/sudoers.pre-ifmi /etc/sudoers
    echo -e "Done!\n"
  fi ;;
  * ) echo -e "installation exited\n";;
esac
