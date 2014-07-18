#!/usr/bin/perl

#    This file is part of IFMI PoolManager.
#
#    PoolManager is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#

use warnings;
use strict;

require '/opt/ifmi/pm-common.pl';
require '/opt/ifmi/sendstatus.pl';
require '/opt/ifmi/pmnotify.pl';

my $conf = &getConfig;
my %conf = %{$conf};

use Proc::Daemon;
use Proc::PID::File;

Proc::Daemon::Init;
if (Proc::PID::File->running()) {
    exit(0);
}

my $continue = 1;
$SIG{TERM} = sub { $continue = 0 };

while ($continue) {

  # Start profile on boot

  if ($conf{settings}{do_boot} == 1) {
    my $uptime = `cat /proc/uptime`;
    $uptime =~ /^(\d+)\.\d+\s+\d+\.\d+/;
    my $rigup = $1;
    if (!-f "/nomine") {
      if ($rigup < 300) {
        my $filecheck = 0; $filecheck = 1 if (-e "/opt/ifmi/nomine");
        my $xcheck1 = `ps -eo command | grep -cE ^/usr/bin/X`;
        my $xcheck2 = `ps -eo command | grep -cE ^X`;
        my $mcheck = `ps -eo command | grep -cE [P]M-miner`;
        if (($xcheck1 == 1 || $xcheck2 == 1) && $mcheck == 0 && $filecheck == 0) {
          &startCGMiner;
          sleep 15;
          &resetPoolSuperPri;
        }
      }
    }
  }


  #  broadcast node status
  if ($conf{farmview}{do_bcast_status} == 1) {
   &bcastStatus;
  }
  # send status direct
  if ($conf{farmview}{do_direct_status} =~ m/\d+\.\d+\.\d+\.\d+/) {
   &directStatus($conf{farmview}{do_direct_status});
  }

  # Email
  if ($conf{monitoring}{do_email} == 1) {
    if (-f "/tmp/pmnotify.lastsent") {
      if (time - (stat ('/tmp/pmnotify.lastsent'))[9] > ($conf{email}{smtp_min_wait} -10)) {
        &doEmail;
      }
    } else { &doEmail; }
  }

  # Graphs should be no older than 5 minutes
  my $graph = "/var/www/IFMI/graphs/msummary.png";
  if (-f $graph) {
    if (time - (stat ($graph))[9] > 290) {
      exec('/opt/ifmi/pmgraph.pl');
    }
  } else {
    exec('/opt/ifmi/pmgraph.pl');
  }

  #Pimp specific
  if (-f "/etc/version") {
     my $pimpcheck = `grep -c pimp /etc/version `;
     &doGpustats if ($pimpcheck > 0);
     &doSysstats if ($pimpcheck > 0);
  }
  # Get the ad
  `wget --quiet -O /opt/ifmi/adata http://ads.miner.farm/pm.html`;

  sleep 60;
}

1;