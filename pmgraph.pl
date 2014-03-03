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
use RRDs;
use IO::Socket::INET;

my $login = (getpwuid $>);
die "must run as root" if ($login ne 'root');

require '/opt/ifmi/pm-common.pl';

my $conf = &getConfig;
my %conf = %{$conf};
my $PICPATH = "/var/www/IFMI/graphs/";
my $DBPATH = "/opt/ifmi/rrdtool/";
my $mport = 4028;
if (defined(${$conf}{'settings'}{'cgminer_port'})) {
       $mport = ${$conf}{'settings'}{'cgminer_port'};
}

if (-e '/tmp/cleargraphs.flag') {
  system('/bin/rm /tmp/cleargraphs.flag');
  system('/bin/rm ' . $DBPATH . '*.rrd');
  system('/bin/rm ' . $PICPATH . '*.png');
}

#GPUs 

my $gpucount = &getCGMinerGPUCount;
  for (my $i=0;$i<$gpucount;$i++)
  {
    my $gnum = $i; 

    my $GDB = $DBPATH . "gpu" . $gnum . ".rrd";
    if (! -f $GDB) { 
      RRDs::create($GDB, "--step=300", 
      "DS:hash:GAUGE:600:U:U",
      "DS:shacc:DERIVE:600:0:U",
      "DS:temp:GAUGE:600:30:100",
      "DS:fanspeed:GAUGE:600:0:100",
      "DS:hwe:COUNTER:600:U:U",
      "RRA:LAST:0.5:1:288", 
      ) or die "Create error: ($RRDs::error)";
    } 

    my $ghash = "0"; my $ghwe = "0"; my $gshacc = "0"; my $gtemp = "0"; my $gfspeed = "0";
    my $sock = new IO::Socket::INET (
     PeerAddr => '127.0.0.1',
     PeerPort => $mport,
     Proto => 'tcp',
     ReuseAddr => 1,
     Timeout => 10,
    );
    if ($sock) {
      print $sock "gpu|$gnum\n";
      my $res = "";
      while(<$sock>) {
       $res .= $_;
      }
      close($sock);
      if ($res =~ m/MHS\sav=(\d+\.\d+),/) {
      	$ghash = $1 * 1000;
      }
      if ($res =~ m/Accepted=(\d+),/) {
      	$gshacc = $1;
      }
      if ($res =~ m/Hardware\sErrors=(\d+),/) {
      	$ghwe = $1;
      }
      if ($res =~ m/Temperature=(\d+\.\d+),/) {
       $gtemp = $1;
      }
      if ($res =~ m/Fan\sPercent=(\d+),/) {
       $gfspeed = $1;
      }
    } else {
    print "cgminer socket failed";
    }

  RRDs::update($GDB, "--template=hash:shacc:temp:fanspeed:hwe", "N:$ghash:$gshacc:$gtemp:$gfspeed:$ghwe")
  or die "Update error: ($RRDs::error)";

  RRDs::graph("-P", $PICPATH . "gpu$gnum.png",
   "--title","24 Hour Summary",
   "--vertical-label","Hashrate K/hs",
   "--right-axis-label","Temp C / Fan % / Shares Acc. x10",
   "--right-axis",".1:0",
   "--start","now-1d",
   "--end", "now",
   "--width","700","--height","300",
   "--color","BACK#00000000",
   "--color","CANVAS#00000000",
   "--border","1", 
   "--font","DEFAULT:0:Helvetica",
   "--font","WATERMARK:4:Helvetica",
   "--slope-mode", "--interlaced",
   "DEF:gdhash=$GDB:hash:LAST",
   "DEF:gdshacc=$GDB:shacc:LAST",
   "DEF:gdtemp=$GDB:temp:LAST",
   "DEF:gdfan=$GDB:fanspeed:LAST",
   "DEF:gdhwe=$GDB:hwe:LAST",
   "CDEF:gcshacc=gdshacc,60,*",
   "VDEF:gvshacc=gcshacc,AVERAGE",
   "CDEF:gccshacc=gdshacc,6000,*",
   "CDEF:gctemp=gdtemp,10,*",
   "CDEF:gcfan=gdfan,10,*",
   "COMMENT:<span font_desc='10'>GPU $gnum</span>",
   "TEXTALIGN:left",
   "AREA:gdhash#4876FF: Hashrate",
   "AREA:gccshacc#32CD32: Shares Accepted / Min",
   "GPRINT:gvshacc:%2.2lf",
   "COMMENT:                 ",
   "LINE3:gctemp#FF7F24: Temp C",
   "LINE3:gcfan#000000: Fan %",
   "TICK:gdhwe#FF0000cc:-0.1: HW error",
   ) or
  die "graph failed ($RRDs::error)";
}

# Summary

my $SDB = $DBPATH . "summary.rrd";
if (! -f $SDB){ 
  RRDs::create($SDB, "--step=300", 
  "DS:mhash:GAUGE:600:U:U",
  "DS:mwu:GAUGE:600:U:U",
  "DS:mshacc:DERIVE:600:0:U",
  "DS:mshrej:DERIVE:600:0:U",
  "DS:mfb:COUNTER:600:U:U",
  "DS:mhwe:COUNTER:600:U:U",
  "RRA:LAST:0.5:1:288", 
  ) or die "Create error: ($RRDs::error)";
} 
my $sock = new IO::Socket::INET (
     PeerAddr => '127.0.0.1',
     PeerPort => $mport,
     Proto => 'tcp',
     ReuseAddr => 1,
     Timeout => 10,
);
if ($sock) {
  print $sock "summary|\n";
  my $res = "";
  while(<$sock>) {
    $res .= $_;
  }
  close($sock);
    my $mhashav = "0";my $mfoundbl = "0";my $maccept = "0";my $mreject = "0";my $mhwerrors = "0";my $mworkutil = "0";
    if ($res =~ m/MHS\sav=(\d+\.\d+),/g) {
      $mhashav = $1 * 1000;
    }
    if ($res =~ m/Found\sBlocks=(\d+),/g) {
      $mfoundbl =$1;
    }
    if ($res =~ m/Accepted=(\d+),/g) {
      $maccept = $1;
    }
    if ($res =~ m/Rejected=(\d+),/g) {
      $mreject = $1;
    }
    if ($res =~ m/Hardware\sErrors=(\d+),/g) {
      $mhwerrors = $1;
    }
    if ($res =~ m/Work\sUtility=(\d+\.\d+),/g) {
      $mworkutil = $1;
    }
   RRDs::update($SDB, "--template=mhash:mwu:mshacc:mshrej:mfb:mhwe", "N:$mhashav:$mworkutil:$maccept:$mreject:$mfoundbl:$mhwerrors")
   or die "Update error: ($RRDs::error)";
}

my $mname = `hostname`;
chomp $mname;
RRDs::graph("-P", $PICPATH . "msummary.png",
 "--title","24 Hour Summary",
 "--vertical-label","Hashrate / WU",
 "--right-axis-label","Shares Acc / Rej",
 "--right-axis",".01:0",
 "--start","now-1d",
 "--end","now",
 "--width","700","--height","200",
 "--color","BACK#00000000",
 "--color","CANVAS#00000000", 
 "--border","1",
 "--font","DEFAULT:0:Helvetica",
 "--font","WATERMARK:4:Helvetica",
 "--slope-mode", "--interlaced",
 "DEF:mdhash=$SDB:mhash:LAST",
 "DEF:mdwu=$SDB:mwu:LAST",
 "DEF:mdshacc=$SDB:mshacc:LAST",
 "DEF:mdshrej=$SDB:mshrej:LAST",
 "DEF:mdhwe=$SDB:mhwe:LAST",
 "DEF:mdfb=$SDB:mfb:LAST",
 "CDEF:mchash=mdhash",
 "VDEF:mvhash=mchash,LAST",
 "CDEF:mcwu=mdwu",
 "VDEF:mvwu=mcwu,LAST",
 "CDEF:mcshacc=mdshacc,6000,*",
 "CDEF:mccshacc=mdshacc,60,*",
 "VDEF:mvshacc=mccshacc,AVERAGE",
 "CDEF:mcshrej=mdshrej,60,*",
 "CDEF:mccshrej=mdshrej,6000,*",
 "VDEF:mvshrej=mcshrej,AVERAGE",
 "VDEF:mvfb=mdfb,LAST",
 "COMMENT:<span font_desc='10'>$mname</span>",
 "TEXTALIGN:left",
 "AREA:mchash#00008B: Hashrate",
 "AREA:mcwu#4876FFcc: WU",
 "TICK:mdfb#505050cc:-0.1: Found Block",
 "TICK:mdhwe#FF0000cc:-0.1: HW Error",
 "AREA:mcshacc#32CD32cc: Avg. Shares Accepted / Min",
 "GPRINT:mvshacc:%2.2lf  ",
 "AREA:mccshrej#EEEE00: Avg. Shares Rejected / Min",
 "GPRINT:mvshrej:%2.2lf  ",
 ) or
 die "graph failed ($RRDs::error)";

# Pools

my $psock = new IO::Socket::INET (
     PeerAddr => '127.0.0.1',
     PeerPort => $mport,
     Proto => 'tcp',
     ReuseAddr => 1,
     Timeout => 10,
);
if ($psock) {
  print $psock "pools|\n";
  my $res = "";
  while(<$psock>) {
    $res .= $_;
  }
  close($psock);

  my $poid = ""; my $pdata = ""; 
  while ($res =~ m/POOL=(\d+),(.+?)\|/g) {
    $poid = $1; $pdata = $2; 
    my $PDB = $DBPATH . "pool$poid.rrd";
    if (! -f $PDB){ 
      RRDs::create($PDB, "--step=300", 
      "DS:plive:GAUGE:600:0:1",
      "DS:pshacc:DERIVE:600:0:U",
      "DS:pshrej:DERIVE:600:0:U",
      "DS:pstale:DERIVE:600:0:U",
      "DS:prfail:COUNTER:600:0:U",
      "RRA:LAST:0.5:1:288", 
      ) or die "Create error: ($RRDs::error)";
    } 
    my $pstat = "0"; my $plive = "0"; my $pacc = "0"; my $prej = "0"; my $pstale = "0"; my $prfails = "0";
    if ($pdata =~ m/Status=(.+?),/) {
      $pstat = $1; $plive = 0; 
      if ($pstat eq "Alive") {
        $plive = 1;
      }
    }
    if ($pdata =~ m/Accepted=(\d+),/) {
      $pacc = $1; 
    }
    if ($pdata =~ m/Rejected=(\d+),/) {
      $prej = $1; 
    }        
    if ($pdata =~ m/Stale=(\d+),/) {
      $pstale = $1; 
    }   
    if ($pdata =~ m/Remote Failures=(\d+),/) {
      $prfails = $1; 
    }  
    RRDs::update($PDB, "--template=plive:pshacc:pshrej:pstale:prfail", "N:$plive:$pacc:$prej:$pstale:$prfails")
    or die "Update error: ($RRDs::error)";

    RRDs::graph("-P", $PICPATH . "pool$poid.png",
     "--title","24 Hour Summary",
     "--vertical-label","Shares Acc / Rej",
     "--start","now-1d",
     "--end", "now",
     "--width","700","--height","300",
     "--color","BACK#00000000",
     "--color","CANVAS#00000000",
     "--border","1",
     "--font","DEFAULT:0:Helvetica",
     "--font","WATERMARK:4:Helvetica",
     "--slope-mode", "--interlaced",
     "DEF:pdlive=$PDB:plive:LAST",
     "DEF:pdshacc=$PDB:pshacc:LAST",
     "DEF:pdshrej=$PDB:pshrej:LAST",
     "DEF:pdstale=$PDB:pstale:LAST",
     "DEF:pdrfail=$PDB:prfail:LAST",
     "CDEF:pcshacc=pdshacc,60,*",
     "VDEF:pvshacc=pcshacc,AVERAGE",
     "CDEF:pcshrej=pdshrej,60,*",
     "VDEF:pvshrej=pcshrej,AVERAGE",
     "CDEF:pcstale=pdstale,60,*",
     "VDEF:pvstale=pcstale,AVERAGE",
     "TEXTALIGN:left",
     "COMMENT:<span font_desc='10'>Pool $poid</span>",
     "AREA:pcshacc#32CD32: Shares Accepted / Min",
     "GPRINT:pvshacc:%2.2lf  ",
     "AREA:pcstale#777777: Stales / Min",
     "GPRINT:pvstale:%2.2lf  ",
     "AREA:pcshrej#EEEE00: Shares Rejected / Min",
     "GPRINT:pvshrej:%2.2lf  ",
     "TICK:pdrfail#FF0000cc:-0.1: Remote Failure",
     ) or
     die "graph failed ($RRDs::error)";
  }
}


