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
if (!defined($conf{settings}{do_bcast_status}) || ($conf{settings}{do_bcast_status} > 0) ) { 
# &blog("broadcasting status");
 &bcastStatus;
}
# status direct
if (defined($conf{settings}{do_direct_status})) {
# &blog("sending status to " . $conf{settings}{do_direct_status});
 &directStatus($conf{settings}{do_direct_status});
}

# graphs should be no older than 5 minutes
my $graph = "/var/www/IFMI/graphs/msummary.png";
my $fileage = time - (stat ($graph))[9];
if (! -e $graph || $fileage > 300) {
  exec('/opt/ifmi/rrdtool/pmgraph.pl'); 
#  &blog("graphs updated"); 
}
my $fcheck = 0; 
if ( defined($conf{settings}{do_farmview}) && ($conf{settings}{do_farmview} == 1) ) {
  $fcheck = `ps -eo command | grep [f]arm | wc -l`;
  if ($fcheck != 0) {
    my $pid = fork();
    if (not defined $pid) {
      die "out of resources? forking failed while starting farmview";
    } elsif ($pid == 0) {
    exec('/opt/ifmi/farmview');
    }
  }
}



