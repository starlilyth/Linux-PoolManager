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
    mv /var/www/favicon.ico /var/www/IFMI/
    mv /var/www/index.html /var/www/IFMI/
    if [ -f /var/www/index.html.pre-ifmi ]; then
      mv /var/www/index.html.pre-ifmi /var/www/index.html
    fi
    mv /usr/lib/cgi-bin/status.pl /var/www/IFMI/status.pl.ifmi
    if [ -f /usr/lib/cgi-bin/status.pl.pre-ifmi ]; then 
      mv /usr/lib/cgi-bin/status.pl.pre-ifmi /usr/lib/cgi-bin/status.pl
    fi
    mv /usr/lib/cgi-bin/confedit.pl /var/www/IFMI/
    mv /etc/sudoers.pre-ifmi /etc/sudoers
    mv /etc/crontab.pre-ifmi /etc/crontab
    rm -r /var/www/IFMI/
    rm -r /opt/ifmi/
    echo -e "Done!\n"
  fi ;;
  * ) echo -e "installation exited\n";;
esac
