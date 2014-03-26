#!/usr/bin/perl

#    This file is part of IFMI PoolManager.
#
#    PoolManager is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#

use YAML qw( DumpFile LoadFile );
use IO::Socket::INET;
use Sys::Syslog qw( :DEFAULT setlogsock);
setlogsock('unix');
use JSON::XS;
use File::Copy;

sub addPool {
  my $purl = $_[0];
  my $puser = $_[1];
  my $ppw = $_[2];
  $ppw = " " if ($ppw eq "");   
  my $pdata = "$purl,$puser,$ppw";
  &sendAPIcommand(addpool,$pdata);
}

sub blog {
  my ($msg) = @_;
  my @parts = split(/\//, $0);
  my $task = $parts[@parts-1];  
  openlog($task,'nofatal,pid','local5');
  syslog('info', $msg);
  closelog;
}

sub CGMinerIsPriv {  
  my $data = &sendAPIcommand(privileged,);
  while ($data =~ m/STATUS=(\w),/g) {
    return $1;
  }
}

sub delPool {
  my $delreq = $_[0];
  &sendAPIcommand(removepool,$delreq); 
}

sub getCGMinerConfig {    
  my $res = &sendAPIcommand(config,);
  if ($res =~ m/Strategy=(.+?),/g) {
    $mstrategy = $1;
  }
  if ($res =~ m/Failover-Only=(\w+),/g) {
    $mfonly = $1;
  }
  if ($res =~ m/ScanTime=(\d+),/g) {
    $mscant = $1;
  }
  if ($res =~ m/Queue=(\d+),/g) {
    $mqueue = $1;
  }
  if ($res =~ m/Expiry=(\d+),/g) {
    $mexpiry = $1;
  }
  push(@mconfig, ({strategy=>$mstrategy, fonly=>$mfonly, scantime=>$mscant, queue=>$mqueue, expiry=>$mexpiry }) );
  return(@mconfig);
}

sub getCGMinerGPUCount {
  my $data = &sendAPIcommand(gpucount,);
  while ($data =~ m/Count=(\d+)/g) {
    return $1; 
  }
}

sub getCGMinerPools {  
  my @pools;
  my $data = &sendAPIcommand(pools,);
  my $poid = ""; $pdata = ""; 
  while ($data =~ m/POOL=(\d+),(.+?)\|/g) {
    $poid = $1; $pdata = $2; 
    if ($pdata =~ m/URL=(.+?),/) {
      $purl = $1; 
    }
    if ($pdata =~ m/Status=(.+?),/) {
      $pstat = $1; 
    }
    if ($pdata =~ m/Priority=(\d+),/) {
      $ppri = $1; 
    }
    if ($pdata =~ m/Quota=(\d+),/) {
      $pquo = $1; 
    }
    if ($pdata =~ m/Long Poll=(.+?),/) {
      $plp = $1; 
    }
    if ($pdata =~ m/Getworks=(\d+),/) {
      $pgw = $1; 
    }
    if ($pdata =~ m/Accepted=(\d+),/) {
      $pacc = $1; 
    }
    if ($pdata =~ m/Rejected=(\d+),/) {
      $prej = $1; 
    }        
    if ($pdata =~ m/Works=(\d+),/) {
      $pworks = $1; 
    }  
    if ($pdata =~ m/Discarded=(\d+),/) {
      $pdisc = $1; 
    }  
    if ($pdata =~ m/Stale=(\d+),/) {
      $pstale = $1; 
    }  
    if ($pdata =~ m/Get Failures=(\d+),/) {
      $pgfails = $1; 
    }  
    if ($pdata =~ m/Remote Failures=(\d+),/) {
      $prfails = $1; 
    }  
    if ($pdata =~ m/User=(.+?),/) {
      $puser = $1; 
    }  
    push(@pools, ({ poolid=>$poid, url=>$purl, status=>$pstat, priority=>$ppri, quota=>$pquo, 
    lp=>$plp, getworks=>$pgw, accepted=>$pacc, rejected=>$prej, works=>$pworks, discarded=>$pdisc, 
    stale=>$pstale, getfails=>$pgfails, remotefailures=>$prfails, user=>$puser }) );
  }
  return(@pools);    
}

sub getCGMinerStats {
  my ($gpu, $data, @pools) = @_;
  my $res = &sendAPIcommand(gpu,$gpu);
  if ($res =~ m/MHS\s\ds=(\d+\.\d+),/) {
    $data->{'hashrate'} = $1 * 1000;
  }
  if ($res =~ m/MHS\sav=(\d+\.\d+),/) {
    $data->{'hashavg'} = $1 * 1000;
  }
  if ($res =~ m/Accepted=(\d+),/) {
    $data->{'shares_accepted'} = $1;
  }   
  if ($res =~ m/Rejected=(\d+),/) {
    $data->{'shares_invalid'} = $1;
  }   
  if ($res =~ m/Status=(\w+),/) {
    $data->{'status'} = $1;
  }
  if ($res =~ m/Enabled=(\w+),/) {
    $data->{'enabled'} = $1;
  }
  if ($res =~ m/Device\sElapsed=(.+?),/) {
    $data->{'elapsed'} = $1; #I get no data here.
  }
  if ($res =~ m/Hardware\sErrors=(\d+),/) {
    $data->{'hardware_errors'} =$1;
  }
  if ($res =~ m/Intensity=(\d+),/) {
    $data->{'intensity'} =$1;
  }   
  if ($res =~ m/Last\sShare\sPool=(\d+),/) {
    foreach $p (@pools) {
      if (${$p}{poolid} == $1) {
        $data->{'pool_url'} =${$p}{url};
      }
    }   
  }
  if ($res =~ m/Last\sShare\sTime=(\d+),/)
  {
    $data->{'last_share_time'} =$1;
  }
  if ($res =~ m/Total\sMH=(\d+)\.\d+,/) {
   $data->{'total_mh'} = $1;
  }
  if ($res =~ m/GPU\sClock=(\d+),/) {
   $data->{'current_core_clock_c'} = $1;
  }
  if ($res =~ m/Memory\sClock=(\d+),/) {
   $data->{'current_mem_clock_c'} = $1;
  }
  if ($res =~ m/GPU\sVoltage=(\d+\.\d+),/) {
   $data->{'current_core_voltage_c'} = $1;
  }
  if ($res =~ m/GPU\sActivity=(.+?),/) {
   $data->{'current_load_c'} = $1;
  }       
  if ($res =~ m/Temperature=(\d+\.\d+),/) {
   $data->{'current_temp_0_c'} = $1;
  }
  if ($res =~ m/Powertune=(\d+),/) {
   $data->{'current_powertune_c'} = $1;
  }
  if ($res =~ m/Fan\sPercent=(\d+),/) {
    $data->{'fan_speed_c'} = $1;
  }
  if ($res =~ m/Fan\sSpeed=(\d+),/) {
    $data->{'fan_rpm_c'} = $1;
  }     
}

sub getCGMinerSummary {    
  my @summary; 
  my $res = &sendAPIcommand(summary,);

  if ($res =~ m/Elapsed=(\d+),/g) {
    $melapsed = $1;
  }
  if ($res =~ m/MHS\sav=(\d+\.\d+),/g) {
    $mhashav = $1;
  }
  if ($res =~ m/MHS\s\ds=(\d+\.\d+),/g) {
    $mhashrate = $1;
  }
  if ($res =~ m/KHS\sav=(\d+),/g) {
    $mkhashav = $1;
  }
  if ($res =~ m/KHS\s\ds=(\d+),/g) {
    $mkhashrate =$1;
  }
  if ($res =~ m/Found\sBlocks=(\d+),/g) {
    $mfoundbl =$1;
  }
  if ($res =~ m/Getworks=(\d+),/g) {
    $mgetworks =$1;
  }
  if ($res =~ m/Accepted=(\d+),/g) {
    $maccept = $1
  }
  if ($res =~ m/Rejected=(\d+),/g) {
    $mreject = $1
  }
  if ($res =~ m/Hardware\sErrors=(\d+),/g) {
    $mhwerrors = $1
  }
  if ($res =~ m/Utility=(.+?),/g) {
    $mutility = $1
  }
  if ($res =~ m/Discarded=(\d+),/g) {
    $mdiscarded = $1
  }
  if ($res =~ m/Stale=(\d+),/g) {
    $mstale = $1
  }
  if ($res =~ m/Get\sFailures=(\d+),/g) {
    $mgetfails = $1
  }
  if ($res =~ m/Local\sWork=(\d+),/g) {
    $mlocalwork = $1
  }
  if ($res =~ m/Remote\sFailures=(\d+),/g) {
    $mremfails = $1
  }
  if ($res =~ m/Network\sBlocks=(\d+),/g) {
    $mnetblocks = $1
  }
  if ($res =~ m/Total\sMH=(\d+\.\d+),/g) {
    $mtotalmh = $1
  }
  if ($res =~ m/Work\sUtility=(\d+\.\d+),/g) {
    $mworkutil = $1
  }
  if ($res =~ m/Difficulty\sAccepted=(\d+\.\d+),/g) {
    $mdiffacc = $1
  }
  if ($res =~ m/Difficulty\sRejected=(\d+\.\d+),/g) {
    $mdiffrej = $1
  }
  if ($res =~ m/Difficulty\sStale=(\d+\.\d+),/g) {
    $mdiffstale = $1
  }
  if ($res =~ m/Best\sShare=(\d+),/g) {
    $mbestshare = $1
  }
  push(@summary, ({elapsed=>$melapsed, hashavg=>$mhashav, hashrate=>$mhashrate, khashavg=>$mkhashav, 
  khashrate=>$mkhashrate, shares_accepted=>$maccept, found_blocks=>$mfoundbl, getworks=>$mgetworks, 
  shares_invalid=>$mreject, hardware_errors=>$mhwerrors, utility=>$mutility, discarded=>$mdiscarded, 
  stale=>$mstale, get_failures=>$mgetfails, local_work=>$mlocalwork, remote_failures=>$mremfails, 
  network_blocks=>$mnetblocks, total_mh=>$mtotalmh, work_utility=>$mworkutil, diff_accepted=>$mdiffacc, 
  diff_rejected=>$mdiffrej, diff_stale=>$mdiffstale, best_share=>$mbestshare }) );
  return(@summary);
}

sub getConfig {
  my $conffile = '/opt/ifmi/poolmanager.conf';
  if (! -e $conffile) {
    exec('/usr/lib/cgi-bin/config.pl');
  } 
  my $c;
  $c = LoadFile($conffile);
  return($c);
}

sub getCGMinerVersion {
  my $data = &sendAPIcommand(version,);
  while ($data =~ m/VERSION,(\w+?=\d+\.\d+\.\d+,API=\d+\.\d+)/g) {
    return $1; 
  }
}

sub getFreshGPUData {
  my @gpus;
  my @cgpools = getCGMinerPools();  
  my $gpucount = &getCGMinerGPUCount;
  my $gidata = "";
  for (my $i=0;$i<$gpucount;$i++) {
    my $gpu = $i; 
    my $res = `DISPLAY=:0.0 /usr/local/bin/atitweak -s`;
    while ($res =~ m/$i\.\s(.+\n)/g) {
      $gidata = $1; 
       if ($gidata =~ m/^(.+?)\s+\(/) {
        $gdesc = $1;
       }  
       if ($gidata =~ m/:(\d+\.\d+)\)/) {
        $gdisp = $1;
       }
    }
    $gpus[$gpu] = ({ desc => $gdesc, display => $gdisp });
    &getCGMinerStats($gpu, \%{$gpus[$gpu]}, @cgpools );   
  }       
  return(@gpus);
}

sub minerExpiry { 
  my $nmexpiry = $_[0];
  my $ecomm = "expiry,$nmexpiry";
  &sendAPIcommand(setconfig,$ecomm);
}

sub minerQueue {
  my $nmqueue = $_[0];
  my $qcomm = "queue,$nmqueue";
  &sendAPIcommand(setconfig,$qcomm);
}

sub minerScantime {
  my $nmscant = $_[0];
  my $scomm = "scantime,$nmscant";
  &sendAPIcommand(setconfig,$scomm);
}

sub priPool {
 my $prilist = $_[0];
  &sendAPIcommand(poolpriority,$prilist); 
}

sub quotaPool {
 my $preq = $_[0];
 my $pqta = $_[1];
 my $qdata = "$preq,$pqta";
  &sendAPIcommand(poolquota,$qdata); 
}

sub saveConfig {
  my $conf = &getConfig;
  my %conf = %{$conf};
  my $runmconf = ${$conf}{settings}{running_mconf}; 
  my $savefile = ${$conf}{miners}{$runmconf}{savepath}; 
  if (-f $savefile) { 
   $bkpfile = $savefile . ".bkp";
   copy $savefile, $bkpfile; 
  }
  &sendAPIcommand(save,$savefile);
}

sub sendAPIcommand {
  my $command = $_[0];
  my $cflags = $_[1];
  my $conf = &getConfig;
  my %conf = %{$conf};
  my $cgport = ${$conf}{settings}{cgminer_port};
  my $sock = new IO::Socket::INET (
    PeerAddr => '127.0.0.1',
    PeerPort => $cgport,
    Proto => 'tcp',
    ReuseAddr => 1,
    Timeout => 10,
  );
  if ($sock) {
    &blog("sending $command $cflags to cgminer api") if (defined(${$conf}{settings}{verbose}));
    print $sock "$command|$cflags\n";
    my $res = "";
    while(<$sock>) {
      $res .= $_;
    }
    close($sock);
    return $res;  
    &blog("success!") if (defined(${$conf}{settings}{verbose}));
  } else {
    &blog("failed to get socket for cgminer api") if (defined(${$conf}{settings}{verbose}));
  }   
}

sub startCGMiner {
  my $conf = &getConfig;
  my %conf = %{$conf};  
  my $currmconf = ${$conf}{settings}{current_mconf}; 
  my $minerbin = ${$conf}{miners}{$currmconf}{mpath}; 
  if ($minerbin eq "") {
    die "No miner path defined! Exiting."; 
  }
  my $mineropts =  ${$conf}{miners}{$currmconf}{mopts};   
  my $pid = fork();   
  if (not defined $pid) {
    die "out of resources? forking failed for cgminer process";
  } elsif ($pid == 0) {
    $ENV{DISPLAY} = ":0";
    $ENV{LD_LIBRARY_PATH} = "/opt/AMD-APP-SDK-v2.4-lnx32/lib/x86/:/opt/AMDAPP/lib/x86_64:";
    $ENV{GPU_USE_SYNC_OBJECTS} = "1";
    $ENV{GPU_MAX_ALLOC_PERCENT} = "100";
    my $cmd = "/usr/bin/screen -d -m -S PM-miner $minerbin $mineropts"; 
    &blog("starting miner with cmd: $cmd") if (defined(${$conf}{settings}{verbose}));
    ${$conf}{settings}{running_mconf} = $currmconf;
    my $conffile = "/opt/ifmi/poolmanager.conf";
    DumpFile($conffile, $conf); 
    exec($cmd);
    exit(0);
  } 
}

sub stopCGMiner {
  &sendAPIcommand(quit,);
}

sub switchPool {
  my $preq = $_[0];
  &sendAPIcommand(switchpool,$preq);
}

sub zeroStats {
  my $zopts = "all,false";
  &sendAPIcommand(zero,$zopts); 
}

1;
