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
Proc::Daemon::Init;

# If already running, then exit
use Proc::PID::File;
if (Proc::PID::File->running()) {
    my $myPID = `/var/run/run-poolmanager.pl.pid`;
    print "ERROR: run-poolmanager already running. Process: $myPID";
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
  
  #Pimp specific
  if (-f "/etc/version") {
     my $pimpcheck = `grep -c pimp /etc/version `;
     &dogpustats if ($pimpcheck > 0);
  }

  sub dogpustats {
    my $conf = &getConfig;
    my %conf = %{$conf};
    my $conffile = "/opt/ifmi/poolmanager.conf";
    my $currentm = $conf{settings}{current_mconf};
    my $msg; 
    my @gpus = &getFreshGPUData;
    if (@gpus) {
      $msg .= "Profile: $conf{miners}{$currentm}{mconfig} ";
      $msg .= "GPU Temps: ";
      for (my $k = 0;$k < @gpus;$k++)
       {
        $msg .= sprintf("%2.0f", $gpus[$k]{'current_temp_0_c'}) . "/";     
       }
       chop $msg; 
       $msg .= " Status: [";
       for (my $k = 0;$k < @gpus;$k++)
       {
         if (${$gpus[$k]}{status} eq "Alive") { $msg .= "A"}
         if (${$gpus[$k]}{status} eq "Dead") { $msg .= "D"}
         if (${$gpus[$k]}{status} eq "Sick") { $msg .= "S"}
  
       # $msg .= ${@gpus[$k]}{status} . " "; 
       }
       $msg .= "]\n";
    } else { $msg .= "GPU Status: Miner not running" }
       #print $msg;
       my $filename = "/tmp/gpustats"
       open my $in, '>', $filename or die; print $in $msg; close $in;
  #     open FILE, ">/tmp/gpustats" or die $!; print FILE $msg; close FILE;
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

  # Get the ad
  `wget --quiet -T 10 -O /opt/ifmi/adata http://ads.miner.farm/pm.html`;

  sleep 60;
}

1;