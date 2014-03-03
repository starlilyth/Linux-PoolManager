#!/usr/bin/perl

#    This file is part of IFMI PoolManager.
#
#    PoolManager is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details. 
#

use warnings;
#use strict;

sub bcastStatus
{

 my $conf = &getConfig;
 my %conf = %{$conf};

 my $mname = `hostname`;
 chomp $mname;

 my $ts = $mname . '|' . ${$conf}{settings}{miner_loc};
 my $k; 
 my @gpus = &getGPUData;
 for ($k = 0;$k < @gpus;$k++)
 {
  $ts .= "|$k:" . encode_json $gpus[$k];
 }
 my $p;
 my @pools = &getCGMinerPools;
 for ($p = 0;$p < @pools;$p++)
 {
  $ts .= "|$p pool:" . encode_json $pools[$p];
 }
 my $s; 
 my @summary = &getCGMinerSummary;
 for ($s = 0;$s < @summary;$s++)
 {
  $ts .= "|$s sum:" . encode_json $summary[$s];
 }

 my $version = &getCGMinerVersion;
 $ts .= "| ver: $version";

 my $port = 54545;

 if (defined(${$conf}{settings}{status_port}))
 {
  $port = ${$conf}{settings}{status_port};
 }

 my $socket = IO::Socket::INET->new(Broadcast => 1, Blocking => 1, ReuseAddr => 1, Type => SOCK_DGRAM, 
  Proto => 'udp', PeerPort => $port, LocalPort => 0, PeerAddr => inet_ntoa(INADDR_BROADCAST));
 
 if ($socket)
 {
 	$socket->send($ts, 0);
	 close $socket;
#   &blog("status sent");
 } else {
   &blog("sendstatus failed to get socket");
 }

}

sub directStatus
{
 my ($target) = @_;

 my $conf = &getConfig;
 my %conf = %{$conf};
 my $mname = `hostname`;
 chomp $mname;

 my $ts = $mname . '|' . ${$conf}{settings}{miner_loc};

 my @gpus = &getGPUData('false');
 my $k; 
 for ($k = 0;$k < @gpus;$k++)
 {
  $ts .= "|$k:" . encode_json $gpus[$k];
 }
 my $p;
 my @pools = &getCGMinerPools;
 for ($p = 0;$p < @pools;$p++)
 {
  $ts .= "|$p pool:" . encode_json $pools[$p];
 }

 my @summary = &getCGMinerSummary;
 my $s; 
 for ($s = 0;$s < @summary;$s++)
 {
  $ts .= "|$s sum:" . encode_json $summary[$s];
 }

 my $version = &getCGMinerVersion;
 $ts .= "| ver: $version";

 my $port = 54545;
 
 if (defined(${$conf}{settings}{status_port}))        
 {
  $port = ${$conf}{settings}{status_port};
 }

 my $socket = IO::Socket::INET->new(Blocking => 1, ReuseAddr => 1, Type => 'SOCK_DGRAM', 
  Proto => 'udp', PeerPort => $port, LocalPort => 0, PeerAddr => $target);
 
 if ($socket)
 {
  $socket->send($ts, 0);
  close $socket;
#   &blog("direct status sent");
 } else {
   &blog("sendstatus failed to get socket");
 }

}


1;
