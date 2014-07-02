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
use YAML qw( DumpFile LoadFile );
use IO::Socket::INET;
use Sys::Syslog qw( :DEFAULT setlogsock);
setlogsock('unix');
use JSON::XS;
use File::Copy;

sub doGpustats {
  my $conf = &getConfig;
  my %conf = %{$conf};
  my $conffile = "/opt/ifmi/poolmanager.conf";
  my $currentm = $conf{settings}{current_mconf};
  my $msg;
  my @gpus = &getFreshGPUData;
  if (@gpus) {
    $msg .= "Miner Status: Profile: $conf{miners}{$currentm}{mconfig} ";
    $msg .= "Temps: [";
    for (my $k = 0;$k < @gpus;$k++) {
      $msg .= sprintf("%2.0f", $gpus[$k]{'current_temp_0_c'}) . "/";
     }
     chop $msg;
     $msg .= "] GPU Status: [";
     for (my $k = 0;$k < @gpus;$k++) {
       if (${$gpus[$k]}{status} eq "Alive") { $msg .= "A"}
       if (${$gpus[$k]}{status} eq "Dead") { $msg .= "D"}
       if (${$gpus[$k]}{status} eq "Sick") { $msg .= "S"}
     }
     $msg .= "]\n";
  } else { $msg .= " GPU Status: Miner not running" }
  open my $fgpustats, '>', "/tmp/gpustats" or die; print $fgpustats $msg; close $fgpustats;
}

sub doSysstats {
  my $conf = &getConfig;
  my %conf = %{$conf};
  my $conffile = "/opt/ifmi/poolmanager.conf";
  my $currentm = $conf{settings}{current_mconf};
  my $minerpath = $conf{miners}{$currentm}{mpath};
  my $mcheck = `ps -eo command | grep -Ec ^$minerpath`;
  my $msg; my $apool; my $minerate;
  my $dhashrates; my $dtemps; my $dstatus; my $mrunt;
  if ($mcheck > 0) {
    my @gpus = &getFreshGPUData;
    if (@gpus) {
      for (my $k = 0;$k < @gpus;$k++) {
        $dtemps .= sprintf("%2.0f", $gpus[$k]{'current_temp_0_c'}) . " ";

        if (${$gpus[$k]}{status} eq "Alive") { $dstatus .= "A "}
        if (${$gpus[$k]}{status} eq "Dead") { $dstatus .= "D "}
        if (${$gpus[$k]}{status} eq "Sick") { $dstatus .= "S "}

        my $ghashrate = $gpus[$k]{'hashrate'};
        $ghashrate = $gpus[$k]{'hashavg'} if ($ghashrate eq "");
        $dhashrates .= sprintf("%d", $ghashrate) . " ";

        #getting the current pool is messy, as it can be different on every gpu.
        my $shorturl; my $poolurl = $gpus[$k]{'pool_url'};
        $poolurl = $1 if ((defined $poolurl) && ($poolurl =~ m/.+\@(.+)/));
        $shorturl = $2 if ((defined $poolurl) && ($poolurl =~ m|://(\w+-?\w+\.)+?(\w+-?\w+\.\w+:\d+)|));
        $shorturl = "N/A" if (! defined $shorturl);
        $apool = $shorturl if ($k == 0);
        if ($k > 0) { $apool = "Multiple" if ($apool ne $shorturl) }
      }
    }
    my @summary = &getCGMinerSummary;
    if (@summary) {
      for (my $i=0;$i<@summary;$i++) {
        my $melapsed = ${$summary[$i]}{'elapsed'};
        $mrunt = sprintf("%d days, %02d:%02d.%02d",(gmtime $melapsed)[7,2,1,0]) if (defined $melapsed);
        my $mratem = ${$summary[$i]}{'hashrate'};
        $mratem = ${$summary[$i]}{'hashavg'} if (!defined $mratem);
        $minerate = sprintf("%.2f", $mratem) if (defined $mratem);
      }
    }

    $msg .= "Current Profile: $conf{miners}{$currentm}{mconfig}\n Device Status: [ $dstatus]\n
Device Hashrates: [ $dhashrates]\n GPU Temps: [ $dtemps]\n Active Pool: $apool\n
Total Hashrate: $minerate\n Miner Runtime: $mrunt\n";

    } else { $msg .= "Miner not started - Stats Unavailable."; }
    print $msg;
    open my $fsysstats, '>', "/tmp/minerstats" or die; print $fsysstats $msg; close $fsysstats;
  }

sub switchProfile {
  my ($swopt) = @_;
  my $conf = &getConfig;
  my %conf = %{$conf};
  my $conffile = "/opt/ifmi/poolmanager.conf";
  my $currentm = $conf{settings}{current_mconf};
  my $minerpath = $conf{miners}{$currentm}{mpath};
  $minerpath = 0 if (!defined $minerpath);
    if (!defined $swopt) {
      print "\nCurrent Profile: " . $conf{miners}{$currentm}{mconfig} . "\n\n";
      print "Available Profles: \n";
        foreach my $mid (sort keys %{$conf{miners}}) {
          my $mname = $conf{miners}{$mid}{mconfig};
          my $mpath = $conf{miners}{$mid}{mpath};
          my $mopts = $conf{miners}{$mid}{mopts};
          my $mconf = $conf{miners}{$mid}{savepath};
          print "$mid - $mname\n";
          print "$mpath $mopts --config $mconf\n"
        }
      print "Usage: 'mcontrol switch X' where X is a profile number.\n";
    } elsif (defined $swopt && $swopt =~ m/^\d+$/) {
      if ($swopt ne $currentm) {
        print "Stopping mining...\n";
        &stopCGMiner();
         ${$conf}{settings}{current_mconf} = $swopt;
         DumpFile($conffile, $conf);
         sleep 15;
        my $mcheck = `ps -eo command | grep -Ec ^$minerpath`;
        if ($mcheck == 0) {
          print "Mining stopped successfully...\nStarting miner on new profile.\n";
          &startCGMiner();
          sleep 10;
          print "Mining started succesfully....Waiting 10 seconds and setting super priority.\n";
          &resetPoolSuperPri;
          print "New profile is started & super priority is set.\n";
        }
      } else {
        print"That config is already running.\n";
      }
    }
  }

sub startMining {
  my $conf = &getConfig;
  my %conf = %{$conf};
  my $conffile = "/opt/ifmi/poolmanager.conf";
  my $currentm = $conf{settings}{current_mconf};
  my $minerpath = $conf{miners}{$currentm}{mpath};
  die "/opt/ifmi/nomine is present, mining disabled until this file is removed." if (-e "/opt/ifmi/nomine");
  my $mcheck = `ps -eo command | grep -Ec ^$minerpath`;
  die "another mining process is running." if ($mcheck > 0);
  print "Starting mining...";
  print "\nCurrent Profile: " . $conf{miners}{$currentm}{mconfig} . "\n";
  &startCGMiner();
  print "Mining started... Waiting 10 seconds and setting super priority.\n";
  &blog("starting miner") if (defined(${$conf}{settings}{verbose}));
  sleep 10;
  &resetPoolSuperPri;
  print "Super priority set.\n";
}

sub addPool {
  my ($purl, $puser, $ppw, $pname, $pdesc, $pprof, $palgo) = @_;
  $ppw = " " if ($ppw eq "");
  my $pdata = "$purl,$puser,$ppw,$pname,$pdesc,$pprof,$palgo";
  &sendAPIcommand("addpool",$pdata);
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
  my $data = &sendAPIcommand("privileged",);
  while ($data =~ m/STATUS=(\w),/g) {
    return $1;
  }
}

sub changeStrategy {
  my $strategy = $_[0];
  my $interval = $_[1];
  my $sreq = "$strategy,$interval";
  &sendAPIcommand("changestrategy",$sreq);
}

sub delPool {
  my $delreq = $_[0];
  &sendAPIcommand("removepool",$delreq);
}

sub getCGMinerProfiles {
  my @mprofiles;
  my $data = &sendAPIcommand("profiles",);
  my $proid; my $prodata;
  while ($data =~ m/PROFILE=(\d+),(.+?)\|/g) {
    $proid = $1; $prodata = $2;
    my $prname; if ($prodata =~ m/Name=(\w+?),/) { $prname = $1; }
    my $prisdef; if ($prodata =~ m/,IsDefault=(\w+?),/) { $prisdef = $1; }
    my $pralgo; if ($prodata =~ m/,Algorithm=(.+?),/) { $pralgo = $1; }
    my $pralgt; if ($prodata =~ m/,Algorithm Type=(\w+?),/) { $pralgt = $1; }
    my $prlg; if ($prodata =~ m/,LookupGap=(\d+?),/) { $prlg = $1; }
    my $prdevs; if ($prodata =~ m/,Devices=(.+?),/) { $prdevs = $1; }
    my $print; if ($prodata =~ m/,Intensity=(\d+?),/) { $print = $1; }
    my $prxint; if ($prodata =~ m/,XIntensity=(\d+?),/) { $prxint = $1; }
    my $prrint; if ($prodata =~ m/,RawIntensity=(\d+?),/) { $prrint = $1; }
    my $prgeng; if ($prodata =~ m/,Gpu Engine=(\d+?),/) { $prgeng = $1; }
    my $prgmem; if ($prodata =~ m/,Gpu MemClock=(\d+?),/) { $prgmem = $1; }
    my $prgthr; if ($prodata =~ m/,Gpu Threads=(\d+?),/) { $prgthr = $1; }
    my $prgfan; if ($prodata =~ m/,Gpu Fan\%=(\d+?),/) { $prgfan = $1; }
    my $prgpt; if ($prodata =~ m/,Gpu Powertune%=(\d+?),/) { $prgpt = $1; }
    my $prgvdc; if ($prodata =~ m/,Gpu Vddc=(\d+?),/) { $prgvdc = $1; }
    my $prsha; if ($prodata =~ m/,Shaders=(\d+?),/) { $prsha = $1; }
    my $prtc; if ($prodata =~ m/,Thread Concurrency=(\d+?),/) { $prtc = $1; }
    my $prws; if ($prodata =~ m/,Worksize=(\d+?),/) { $prws = $1; }
    push(@mprofiles, ({profid=> $proid, name=>$prname, is_default=>$prisdef, algo=>$pralgo,
      algo_type=>$pralgt, lookup_gap=>$prlg, devices=>$prdevs, intensity=>$print, x_int=>$prxint,
      raw_int=>$prrint, gpu_engine=>$prgeng, gpu_memclock=>$prgmem, gpu_threads=>$prgthr, gpu_fan=>$prgfan,
      gpu_ptune=>$prgpt, gpu_vddc=>$prgvdc, shaders=>$prsha, thread_con=>$prtc, worksize=>$prws}) );
  }
  return(@mprofiles);
}


sub getCGMinerConfig {
  my @mconfig;
  my $res = &sendAPIcommand("config",);
  my $mstrategy; if ($res =~ m/Strategy=(.+?),/g) { $mstrategy = $1; }
  my $mfonly; if ($res =~ m/Failover-Only=(\w+),/g) { $mfonly = $1; }
  my $mscant; if ($res =~ m/ScanTime=(\d+),/g) { $mscant = $1; }
  my $mqueue; if ($res =~ m/Queue=(\d+),/g) { $mqueue = $1; }
  my $mexpiry; if ($res =~ m/Expiry=(\d+),/g) { $mexpiry = $1; }
  push(@mconfig, ({strategy=>$mstrategy, fonly=>$mfonly, scantime=>$mscant, queue=>$mqueue, expiry=>$mexpiry }) );
  return(@mconfig);
}

sub getCGMinerGPUCount {
  my $data = &sendAPIcommand("gpucount",);
  while ($data =~ m/Count=(\d+)/g) {
    return $1;
  }
}

sub getCGMinerPools {
  my @pools;
  my $data = &sendAPIcommand("pools",);
  my $poid; my $pdata;
  while ($data =~ m/POOL=(\d+),(.+?)\|/g) {
    $poid = $1; $pdata = $2;
    my $purl; if ($pdata =~ m/URL=(.+?),/) { $purl = $1; }
    my $pstat; if ($pdata =~ m/Status=(.+?),/) { $pstat = $1; }
    my $ppri; if ($pdata =~ m/Priority=(\d+),/) { $ppri = $1; }
    my $pquo; if ($pdata =~ m/Quota=(\d+),/) { $pquo = $1; }
    my $plp; if ($pdata =~ m/Long Poll=(.+?),/) { $plp = $1; }
    my $pgw; if ($pdata =~ m/Getworks=(\d+),/) { $pgw = $1; }
    my $pacc; if ($pdata =~ m/Accepted=(\d+),/) { $pacc = $1; }
    my $prej; if ($pdata =~ m/Rejected=(\d+),/) { $prej = $1; }
    my $pworks; if ($pdata =~ m/Works=(\d+),/) { $pworks = $1; }
    my $pdisc; if ($pdata =~ m/Discarded=(\d+),/) { $pdisc = $1; }
    my $pstale; if ($pdata =~ m/Stale=(\d+),/) { $pstale = $1; }
    my $pgfails; if ($pdata =~ m/Get Failures=(\d+),/) { $pgfails = $1; }
    my $prfails; if ($pdata =~ m/Remote Failures=(\d+),/) { $prfails = $1; }
    my $puser; if ($pdata =~ m/User=(.+?),/) { $puser = $1; }
    my $pprofile; if ($pdata =~ m/Profile=(.+?),/) { $pprofile = $1; }
    my $palgo; if ($pdata =~ m/Algorithm=(.+?),/) { $palgo = $1; }
    my $palgt; if ($pdata =~ m/Algorithm Type=(.+?),/) { $palgt = $1; }
    my $pname; if ($pdata =~ m/Name=(.+?),/) { $pname = $1; }
    my $pdesc; if ($pdata =~ m/Description=(.+?),/) { $pdesc = $1; }
    push(@pools, ({ poolid=>$poid, url=>$purl, status=>$pstat, priority=>$ppri, quota=>$pquo,
    lp=>$plp, getworks=>$pgw, accepted=>$pacc, rejected=>$prej, works=>$pworks, discarded=>$pdisc,
    stale=>$pstale, getfails=>$pgfails, remotefailures=>$prfails, user=>$puser, profile=>$pprofile,
    algo=>$palgo, algo_type=>$palgt, name=>$pname, descr=>$pdesc }) );
  }
  return(@pools);
}

sub getCGMinerStats {
  my ($gpu, $data, @pools) = @_;
  my $res = &sendAPIcommand("gpu",$gpu);
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
  if ($res =~ m/XIntensity=(\d+),/) {
    $data->{'xintensity'} =$1;
  }
  if ($res =~ m/RawIntensity=(\d+),/) {
    $data->{'rintensity'} =$1;
  }
  if ($res =~ m/Last\sShare\sPool=(\d+),/) {
    foreach my $p (@pools) {
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
  my $res = &sendAPIcommand("summary",);
  my $melapsed; if ($res =~ m/Elapsed=(\d+),/g) { $melapsed = $1; }
  my $mhashav; if ($res =~ m/MHS\sav=(\d+\.\d+),/g) { $mhashav = $1; }
  my $mhashrate; if ($res =~ m/MHS\s\ds=(\d+\.\d+),/g) { $mhashrate = $1; }
  my $mkhashav; if ($res =~ m/KHS\sav=(\d+),/g) { $mkhashav = $1; }
  my $mkhashrate; if ($res =~ m/KHS\s\ds=(\d+),/g) { $mkhashrate =$1; }
  my $mfoundbl; if ($res =~ m/Found\sBlocks=(\d+),/g) { $mfoundbl =$1; }
  my $mgetworks; if ($res =~ m/Getworks=(\d+),/g) { $mgetworks =$1; }
  my $maccept; if ($res =~ m/Accepted=(\d+),/g) { $maccept = $1 }
  my $mreject; if ($res =~ m/Rejected=(\d+),/g) { $mreject = $1 }
  my $mhwerrors; if ($res =~ m/Hardware\sErrors=(\d+),/g) { $mhwerrors = $1 }
  my $mutility; if ($res =~ m/Utility=(.+?),/g) { $mutility = $1 }
  my $mdiscarded; if ($res =~ m/Discarded=(\d+),/g) { $mdiscarded = $1 }
  my $mstale; if ($res =~ m/Stale=(\d+),/g) { $mstale = $1 }
  my $mgetfails; if ($res =~ m/Get\sFailures=(\d+),/g) { $mgetfails = $1 }
  my $mlocalwork; if ($res =~ m/Local\sWork=(\d+),/g) { $mlocalwork = $1 }
  my $mremfails; if ($res =~ m/Remote\sFailures=(\d+),/g) { $mremfails = $1 }
  my $mnetblocks; if ($res =~ m/Network\sBlocks=(\d+),/g) { $mnetblocks = $1 }
  my $mtotalmh; if ($res =~ m/Total\sMH=(\d+\.\d+),/g) { $mtotalmh = $1 }
  my $mworkutil; if ($res =~ m/Work\sUtility=(\d+\.\d+),/g) { $mworkutil = $1 }
  my $mdiffacc; if ($res =~ m/Difficulty\sAccepted=(\d+\.\d+),/g) { $mdiffacc = $1 }
  my $mdiffrej; if ($res =~ m/Difficulty\sRejected=(\d+\.\d+),/g) { $mdiffrej = $1 }
  my $mdiffstale; if ($res =~ m/Difficulty\sStale=(\d+\.\d+),/g) { $mdiffstale = $1 }
  my $mbestshare; if ($res =~ m/Best\sShare=(\d+),/g) { $mbestshare = $1 }
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
  my $data = &sendAPIcommand("version",);
  while ($data =~ m/VERSION(.+)\|/g) {
    return $1;
  }
}

sub getFreshGPUData {
  my @gpus;
  my @cgpools = getCGMinerPools();
  my $gpucount = &getCGMinerGPUCount;
  my $gidata; my $gdesc; my $gdisp;
  for (my $i=0;$i<$gpucount;$i++) {
    my $gpu = $i;
    if (-e "/usr/local/bin/atitweak") {
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
    } else {
      $gdesc = "unknown";
      $gdisp = "0.0";
    }
    $gpus[$gpu] = ({ desc => $gdesc, display => $gdisp });
    &getCGMinerStats($gpu, \%{$gpus[$gpu]}, @cgpools );
  }
  return(@gpus);
}

sub minerExpiry {
  my $nmexpiry = $_[0];
  my $ecomm = "expiry,$nmexpiry";
  &sendAPIcommand("setconfig",$ecomm);
}

sub minerQueue {
  my $nmqueue = $_[0];
  my $qcomm = "queue,$nmqueue";
  &sendAPIcommand("setconfig",$qcomm);
}

sub minerScantime {
  my $nmscant = $_[0];
  my $scomm = "scantime,$nmscant";
  &sendAPIcommand("setconfig",$scomm);
}

sub priPool {
 my $prilist = $_[0];
  &sendAPIcommand("poolpriority",$prilist);
}

sub quotaPool {
 my $preq = $_[0];
 my $pqta = $_[1];
 my $qdata = "$preq,$pqta";
  &sendAPIcommand("poolquota",$qdata);
}

sub saveConfig {
  my $conf = &getConfig;
  my %conf = %{$conf};
  my $runmconf = ${$conf}{settings}{running_mconf};
  my $savefile = ${$conf}{miners}{$runmconf}{savepath};
  if (-f $savefile) {
   my $bkpfile = $savefile . ".bkp";
   copy $savefile, $bkpfile;
  }
  &blog("saving $savefile...") if (defined(${$conf}{settings}{verbose}));
  &sendAPIcommand("save",$savefile);
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
    if (defined $cflags) {
      &blog("sending \"$command $cflags\" to cgminer api") if (defined(${$conf}{settings}{verbose}));
      print $sock "$command|$cflags";
    } else {
      &blog("sending \"$command\" to cgminer api") if (defined(${$conf}{settings}{verbose}));
      print $sock "$command|\n";
    }
    my $res = "";
    while(<$sock>) {
      $res .= $_;
    }
    close($sock);
    &blog("success!") if (defined(${$conf}{settings}{verbose}));
    return $res;
  } else {
    &blog("failed to get socket for cgminer api") if (defined(${$conf}{settings}{verbose}));
  }
}

sub setGPUDisable {
 my $gpuid = $_[0];
 &sendAPIcommand("gpudisable",$gpuid);
}

sub setGPUEnable {
 my $gpuid = $_[0];
 &sendAPIcommand("gpuenable",$gpuid);
}

sub setGPUEngine {
 my $gpuid = $_[0];
 my $geng = $_[1];
 my $gef = "$gpuid,$geng";
 &sendAPIcommand("gpuengine",$gef);
}

sub setGPUIntensity {
 my $gpuid = $_[0];
 my $gint = $_[1];
 my $gif = "$gpuid,$gint";
 &sendAPIcommand("gpuintensity",$gif);
}

sub setGPUMem {
 my $gpuid = $_[0];
 my $gmem = $_[1];
 my $gmf = "$gpuid,$gmem";
 &sendAPIcommand("gpumem",$gmf);
}

sub setGPURestart {
 my $gpuid = $_[0];
 &sendAPIcommand("gpurestart",$gpuid);
}

sub setPoolSuperPri {
  my $spool = $_[0];
  my $conf = &getConfig;
  my %conf = %{$conf};
  my $conffile = '/opt/ifmi/poolmanager.conf';
  my $acount = 0;
  for (keys %{$conf{pools}}) {
    if ((${$conf}{pools}{$_}{spri} == 1) && ($spool ne ${$conf}{pools}{$_}{url})) {
      ${$conf}{pools}{$_}{spri} = 0;
    }
    if ($spool eq ${$conf}{pools}{$_}{url}) {
      ${$conf}{pools}{$_}{spri} = 1;
      $acount++;
    }
  }
  if ($acount == 0 && $spool ne "z") {
    my $newa = (keys %{$conf{pools}}); $newa++;
    ${$conf}{pools}{$newa}{url} = $spool;
    ${$conf}{pools}{$newa}{spri} = 1;
  }
  DumpFile($conffile, $conf);
  &resetPoolSuperPri;
}

sub resetPoolSuperPri {
  my $conf = &getConfig;
  my %conf = %{$conf};
  my $pnum; my $spool = "x";
  my @pools = &getCGMinerPools(1);
  for (keys %{$conf{pools}}) {
    my $spval = ${$conf}{pools}{$_}{spri};
    if (defined $spval && $spval == 1) {
      $spool = ${$conf}{pools}{$_}{url};
    }
  }
  for (my $i=0;$i<@pools;$i++) {
    my $pname = ${$pools[$i]}{'url'};
    if ($spool eq $pname) {
      $pnum = ${$pools[$i]}{'poolid'};
      &sendAPIcommand("poolpriority",$pnum);
    }
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
  my $savepath = ${$conf}{miners}{$currmconf}{savepath};
  my $pid = fork();
  if (not defined $pid) {
    die "out of resources? forking failed for cgminer process";
  } elsif ($pid == 0) {
    $ENV{DISPLAY} = ":0";
    $ENV{LD_LIBRARY_PATH} = "/opt/AMD-APP-SDK-v2.4-lnx32/lib/x86/:/opt/AMDAPP/lib/x86_64:";
    $ENV{GPU_USE_SYNC_OBJECTS} = "1";
    $ENV{GPU_MAX_ALLOC_PERCENT} = "100";
    my $cmd = "cd /opt/ifmi; /usr/bin/screen -d -m -S PM-miner $minerbin --config $savepath $mineropts";
    &blog("starting miner with cmd: $cmd") if (defined(${$conf}{settings}{verbose}));
    ${$conf}{settings}{running_mconf} = $currmconf;
    my $conffile = "/opt/ifmi/poolmanager.conf";
    DumpFile($conffile, $conf);
    exec($cmd);
    exit(0);
  }
}

sub stopCGMiner {
  &sendAPIcommand("quit",);
}

sub switchPool {
  my $preq = $_[0];
  &sendAPIcommand("switchpool",$preq);
}

sub zeroStats {
  my $zopts = "all,false";
  &sendAPIcommand("zero",$zopts);
}

1;
