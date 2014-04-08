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

use Proc::PID::File;
if (Proc::PID::File->running()) {
  # one at a time, please
  print "Another run-poolmanager is running.\n";
  exit(0);
}

# Start profile on boot

if ($conf{settings}{do_boot} == 1) {
  my $uptime = `cat /proc/uptime`;
  $uptime =~ /^(\d+)\.\d+\s+\d+\.\d+/;
  my $rigup = $1;
  if (($rigup < 300)) {
    my $xcheck = `ps -eo command | grep -cE ^/usr/bin/X`;
    my $mcheck = `ps -eo command | grep -cE [P]M-miner`;
    if ($xcheck == 1 && $mcheck == 0) {
      &startCGMiner;
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

# FarmView
if ($conf{farmview}{do_farmview} == 1) {
  &doFarmview; 
}
if ($conf{farmview}{do_farmview} == 0) {
  &undoFarmview; 
}
if (-f "/tmp/rfv") {
  if ($conf{farmview}{do_farmview} == 1) {
    &undoFarmview;
    &doFarmview;
  }
  exec('/bin/rm /tmp/rfv');
}


sub doFarmview {
  my $fcheck = `/bin/ps -eo command | /bin/grep -Ec /opt/ifmi/farmview\$`;
  if ($fcheck == 0) {
    my $pid = fork();
    if (not defined $pid) {
      die "out of resources? forking failed while starting farmview";
    } elsif ($pid == 0) {
    exec('/opt/ifmi/farmview');
    }
  }
}

sub undoFarmview { 
  if (-f "/var/run/farmview.pid") {
    my $fvpid = `/bin/cat /var/run/farmview.pid`;
    `/bin/kill $fvpid`;
    `/bin/rm /var/run/farmview.pid`;
  }
}


