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

my $conf = &getConfig;
my %conf = %{$conf};

# status bcast
if (!defined($conf{farmview}{do_bcast_status}) || ($conf{farmview}{do_bcast_status} > 0) ) { 
# &blog("broadcasting status");
 &bcastStatus;
}
# status direct
if ($conf{farmview}{do_direct_status} =~ m/\d+\.\d+\.\d+\.\d+/) {
# &blog("sending status to " . $conf{farmview}{do_direct_status});
 &directStatus($conf{farmview}{do_direct_status});
}

# graphs should be no older than 5 minutes
my $graph = "/var/www/IFMI/graphs/msummary.png";
my $fileage = time - (stat ($graph))[9];
if (! -e $graph || $fileage > 300) {
  exec('/opt/ifmi/rrdtool/pmgraph.pl'); 
#  &blog("graphs updated"); 
}

# 
if ($conf{farmview}{do_farmview} == 1) {
  &doFarmview; 
}
if ($conf{farmview}{do_farmview} == 0) {
  &undoFarmview; 
}
if (-e "/tmp/rfv") {
  &undoFarmview;
  &doFarmview;
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
  if (-e "/var/run/farmview.pid") {
    my $fvpid = `cat /var/run/farmview.pid`;
    `/bin/kill $fvpid`;
    `/bin/rm /var/run/farmview.pid`;
  }
}







