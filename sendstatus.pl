#!/usr/bin/perl

#    This file is part of IFMI PoolManager.
#
#    PoolManager is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details. 
#

require '/opt/ifmi/pm-common.pl';

my $conf = &getConfig;
%conf = %{$conf};

if (!defined($conf{settings}{do_bcast_status}) || ($conf{settings}{do_bcast_status} > 0) )
{
 &bcastStatus;
}

# status direct
if (defined($conf{settings}{do_direct_status}))
{
 &directStatus($conf{settings}{do_direct_status});
}


sub bcastStatus
{

 my $conf = &getConfig;
 %conf = %{$conf};

 my $ts = ${$conf}{settings}{miner_id} . '|' . ${$conf}{settings}{miner_loc};

 my @gpus = &getGPUData(false);
 for ($k = 0;$k < @gpus;$k++)
 {
  $ts .= "|$k:" . encode_json $gpus[$k];
 }

 my @pools;  my @pools = &getCGMinerPools;
 for ($p = 0;$p < @pools;$p++)
 {
  $ts .= "|$p pool:" . encode_json $pools[$p];
 }

 my @summary; my @summary = &getCGMinerSummary;
 for ($s = 0;$s < @summary;$s++)
 {
  $ts .= "|$s sum:" . encode_json $summary[$s];
 }

 my $version; my $version = &getCGMinerVersion;
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
 } else {
   &blog("sendstatus failed to get socket");
 }

}

sub directStatus
{
 my ($target) = @_;

 my $conf = &getConfig;
 %conf = %{$conf};

 my $ts = ${$conf}{settings}{miner_id} . '|' . ${$conf}{settings}{miner_loc};

 my @gpus = &getGPUData(false);

 for ($k = 0;$k < @gpus;$k++)
 {
  $ts .= "|$k:" . encode_json $gpus[$k];
 }

 my @pools = &getCGMinerPools;

 for ($p = 0;$p < @pools;$p++)
 {
  $ts .= "|$p pool:" . encode_json $pools[$p];
 }

 my @summary = &getCGMinerSummary;

 for ($s = 0;$s < @summary;$s++)
 {
  $ts .= "|$s sum:" . encode_json $summary[$s];
 }

 my @version = &getCGMinerVersion;

 for ($v = 0;$v < @version;$v++)
 {
  $ts .= "|$v ver:" . encode_json $version[$v];
 }

 my $port = 54545;
 
 if (defined(${$conf}{settings}{status_port}))        
 {
  $port = ${$conf}{settings}{status_port};
 }

 my $socket = IO::Socket::INET->new(Blocking => 1, ReuseAddr => 1, Type => SOCK_DGRAM, 
  Proto => 'udp', PeerPort => $port, LocalPort => 0, PeerAddr => $target);
 
 if ($socket)
 {
  $socket->send($ts, 0);
  close $socket;
 } else {
   &blog("sendstatus failed to get socket");
 }

}


1;
