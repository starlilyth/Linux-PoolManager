#!/bin/bash

# Install script for IFMI PoolManager

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi
echo "This script will install the IFMI PoolManager for cgminer and clones."
read -p "Are you sure?(y/n)" input
shopt -s nocasematch
case "$input" in
  y|Y|Yes)
  if [ -d /var/www/IFMI ]; then
    read -p  "It looks like this has been installed before. Do over?(y/n)" overwrite
    shopt -s nocasematch
    case "$overwrite" in
      y|Y|Yes)
      echo -e "Copying files...\n"
      mkdir -p /var/www/IFMI/graphs
      mkdir -p /opt/ifmi/rrdtool
      cp /var/www/IFMI/status.css /var/www/IFMI/status.css.back
      cp status.css /var/www/IFMI/
      cp ./images/*.png /var/www/IFMI
      cp /usr/lib/cgi-bin/status.pl /usr/lib/cgi-bin/status.pl.back
      cp status.pl /usr/lib/cgi-bin/
      cp /usr/lib/cgi-bin/confedit.pl /usr/lib/cgi-bin/confedit.pl.back
      cp confedit.pl /usr/lib/cgi-bin/
      cp /opt/ifmi/mcontrol /opt/ifmi/mcontrol.back
      cp mcontrol /opt/ifmi/
      cp /opt/ifmi/sendstatus.pl /opt/ifmi/sendstatus.pl.back
      cp sendstatus.pl /opt/ifmi/
      cp /opt/ifmi/farmview /opt/ifmi/farmview.back
      cp farmview /opt/ifmi/
      cp /var/www/IFMI/farmview.css /var/www/IFMI/farmview.css.back
      cp farmview.css /var/www/IFMI/
      cp /opt/ifmi/pm-common.pl /opt/ifmi/pm-common.pl.back
      cp pm-common.pl /opt/ifmi/
      cp /opt/ifmi/poolmanager.conf /opt/ifmi/poolmanager.conf.back
      cp poolmanager.conf /opt/ifmi/
      cp /opt/ifmi/pmgraph.pl /opt/ifmi/pmgraph.pl.back
      cp pmgraph.pl /opt/ifmi/rrdtool
      if ! grep -q  "run-poolmanager" "/etc/crontab" ; then
        echo -e "* * * * * root /opt/ifmi/run-poolmanager.pl\n" >> /etc/crontab
      fi   
      chmod +x /usr/lib/cgi-bin/*.pl #because windows
      echo -e "Done!\n";;
      * ) echo -e "installation exited\n";;
    esac
  else
    if [ -d /var/www ] && [ -d /usr/lib/cgi-bin ]; then
      echo -e "Copying files...\n"
      mkdir -p /var/www/IFMI/graphs
      mkdir -p /opt/ifmi/rrdtool
      if [ -f /var/www/index.html ]; then
        cp /var/www/index.html /var/www/index.html.pre-ifmi
      fi
      cp index.html /var/www/
      cp favicon.ico /var/www/
      cp status.css /var/www/IFMI/
      cp ./images/*.png /var/www/IFMI
      if [ -f /usr/lib/cgi-bin/status.pl ]; then
        cp /usr/lib/cgi-bin/status.pl /usr/lib/cgi-bin/status.pl.pre-ifmi
      fi
      cp status.pl /usr/lib/cgi-bin/
      cp confedit.pl /usr/lib/cgi-bin/
      cp mcontrol /opt/ifmi/
      cp pm-common.pl /opt/ifmi/
      cp poolmanager.conf /opt/ifmi/
      cp sendstatus.pl /opt/ifmi/
      cp farmview /opt/ifmi/
      cp farmview.css /var/www/IFMI/
      cp pmgraph.pl /opt/ifmi/rrdtool
      echo -e "* * * * * root /opt/ifmi/run-poolmanager.pl\n" >> /etc/crontab
      chmod +x /usr/lib/cgi-bin/*.pl #because windows
      echo -e "Modifying sudoers....\n"
      if [ -f /etc/redhat-release ]; then 
        sed \$a"Defaults targetpw\n"\
"apache ALL=(ALL) /opt/ifmi/mcontrol,/bin/cp,/usr/bin/reboot\n" /etc/sudoers > /etc/sudoers.ifmi
      cp /etc/sudoers /etc/sudoers.pre-ifmi
      cp /etc/sudoers.ifmi /etc/sudoers
      elif [ -f /etc/debian_version ]; then 
        sed \$a"Defaults targetpw\n"\
"www-data ALL=(ALL) /opt/ifmi/mcontrol,/bin/cp,/sbin/reboot\n" /etc/sudoers > /etc/sudoers.ifmi
      cp /etc/sudoers /etc/sudoers.pre-ifmi
      cp /etc/sudoers.ifmi /etc/sudoers
      else 
        echo -e "Cant determine distro, skipping sudoers... PLEASE SEE THE README!\n"
      fi 
      echo -e "Running Apache security script...\n"
      ./htsec.sh
      echo -e "Done! Please read the README and edit your conf file as required. Thank you for flying IFMI!\n"
    else
      echo -e "Your web directories are in unexpected places. Quitting.\n"
      exit 1;
    fi
  fi ;;
  * ) echo -e "installation exited\n";;
esac
