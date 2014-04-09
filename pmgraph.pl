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
use YAML qw( LoadFile );

my $login = (getpwuid $>);
die "must run as root" if ($login ne 'root');

require '/opt/ifmi/pm-common.pl';

my $conf = &getConfig;
my %conf = %{$conf};
my $PICPATH = "/var/www/IFMI/graphs/";
my $DBPATH = "/opt/ifmi/rrdtool/";
my $ERR = RRDs::error;

my $colorfile = "/var/www/IFMI/themes/" . ${$conf}{display}{'graphcolors'}; 
my $gconf = LoadFile($colorfile) if (-f $colorfile);
my $hashcolor = "#0033FF";
$hashcolor = $gconf->{hashcolor} if (defined ($gconf->{hashcolor}));
my $wucolor = "#4876FFcc"; 
$wucolor = $gconf->{wucolor} if (defined ($gconf->{wucolor}));
my $acccolor = "#32CD32cc";
$acccolor = $gconf->{acccolor} if (defined ($gconf->{acccolor}));
my $rejcolor = "#EEEE00";
$rejcolor = $gconf->{rejcolor} if (defined ($gconf->{rejcolor}));
my $stfcolor = "#777777cc";
$stfcolor = $gconf->{stfcolor} if (defined ($gconf->{stfcolor})); 
my $fontcolor = "#000000";
$fontcolor = $gconf->{fontcolor} if (defined ($gconf->{fontcolor}));
my $fancolor = "#000000";
$fancolor = $gconf->{fancolor} if (defined ($gconf->{fancolor}));
my $tempcolor = "#FF7F24";
$tempcolor = $gconf->{tempcolor} if (defined ( $gconf->{tempcolor})); 
my $errorcolor = "#FF0000cc";
$errorcolor = $gconf->{errorcolor} if (defined ($gconf->{errorcolor})); 
my $fontfam = "Helvetica";
$fontfam = $gconf->{fontfam} if (defined ($gconf->{fontfam}));
my $gpucolor0 = "#FF0000";
$gpucolor0 = $gconf->{gpucolor0} if (defined ( $gconf->{gpucolor0})); 
my $gpucolor1 = "#FF00FF";
$gpucolor1 = $gconf->{gpucolor1} if (defined ( $gconf->{gpucolor1})); 
my $gpucolor2 = "#FF3300";
$gpucolor2 = $gconf->{gpucolor2} if (defined ( $gconf->{gpucolor2})); 
my $gpucolor3 = "#FF6600";
$gpucolor3 = $gconf->{gpucolor3} if (defined ( $gconf->{gpucolor3})); 
my $gpucolor4 = "#FF9900";
$gpucolor4 = $gconf->{gpucolor4} if (defined ( $gconf->{gpucolor4})); 
my $gpucolor5 = "#FFCC00";
$gpucolor5 = $gconf->{gpucolor5} if (defined ( $gconf->{gpucolor5})); 
my $gpucolor6 = "#CC0000";
$gpucolor6 = $gconf->{gpucolor6} if (defined ( $gconf->{gpucolor6})); 
my $gpucolor7 = "#CC00FF";
$gpucolor7 = $gconf->{gpucolor7} if (defined ( $gconf->{gpucolor7}));
my $gpucolor8 = "#CC3300";
$gpucolor8 = $gconf->{gpucolor8} if (defined ( $gconf->{gpucolor8}));
my $gpucolor9 = "#CC6600";
$gpucolor9 = $gconf->{gpucolor9} if (defined ( $gconf->{gpucolor9}));

if (-f '/tmp/cleargraphs.flag') {
  system('/bin/rm /tmp/cleargraphs.flag');
  system('/bin/rm ' . $DBPATH . '*.rrd');
  system('/bin/rm ' . $PICPATH . '*.png');
}

#GPUs 
my $ispriv = &CGMinerIsPriv; 
if ($ispriv eq "S") {

  my $gpucount = &getCGMinerGPUCount;
  my $temphi = ${$conf}{monitoring}{monitor_temp_hi};
  my $templo = ${$conf}{monitoring}{monitor_temp_lo};

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
      );
      die "graph failed: $ERR\n" if $ERR;
    }

    my $ghash = "0"; my $ghwe = "0"; my $gshacc = "0"; my $gtemp = "0"; my $gfspeed = "0";
    my $res = &sendAPIcommand("gpu",$i);
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

  RRDs::update($GDB, "--template=hash:shacc:temp:fanspeed:hwe", "N:$ghash:$gshacc:$gtemp:$gfspeed:$ghwe");
  die "graph failed: $ERR\n" if $ERR;

  my $temphig = $temphi * 100;
  RRDs::graph("-P", $PICPATH . "gpu$gnum.png",
   "--title","24 Hour Summary",
   "--vertical-label","Hashrate K/hs",
   "--right-axis-label","Temp C / Fan % / Shares Acc. x10",
   "--right-axis",".1:0",
   "--start","now-1d",
   "--end", "now",
   "--width","700","--height","200",
   "--color","BACK#00000000",
   "--color","CANVAS#00000000",
   "--color","FONT$fontcolor",
   "--border","1", 
   "--font","DEFAULT:0:$fontfam",
   "--font","WATERMARK:4:$fontfam",
   "--slope-mode", "--interlaced",
   "HRULE:$temphig#FF0000",
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
   "AREA:gdhash$hashcolor: Hashrate",
   "AREA:gccshacc$acccolor: Shares Accepted / Min",
   "GPRINT:gvshacc:%2.2lf",
   "COMMENT:                 ",
   "LINE3:gctemp$tempcolor: Temp C",
   "LINE3:gcfan$fancolor: Fan %",
   "TICK:gdhwe$errorcolor:-0.1: HW error",
   );
  die "graph failed: $ERR\n" if $ERR;
  }

  my @gdata = (
    $PICPATH . 'gsummary.png',
    "--vertical-label=GPU Temps",
    "--start=now-1d",
    "--end=now",
    "--width=700","--height=100",
    "--color=BACK#00000000",
    "--color=CANVAS#00000000",
    "--color=FONT$fontcolor",
    "--border","0",
    "--font=DEFAULT:0:$fontfam",
    "--font=WATERMARK:5:$fontfam",
    "--slope-mode","--interlaced",
    "HRULE:$temphi#FF0000",
    "HRULE:$templo#0000FF"
  );
  my @gpucolor;
  $gpucolor[0] = $gpucolor0;
  $gpucolor[1] = $gpucolor1;
  $gpucolor[2] = $gpucolor2;
  $gpucolor[3] = $gpucolor3;
  $gpucolor[4] = $gpucolor4;
  $gpucolor[5] = $gpucolor5;
  $gpucolor[6] = $gpucolor6;
  $gpucolor[7] = $gpucolor7;
  $gpucolor[8] = $gpucolor8;
  $gpucolor[9] = $gpucolor9;
  for (my $g=0;$g<$gpucount;$g++) {
    my $GDB = $DBPATH . "gpu" . $g . ".rrd";
    push @gdata, 'DEF:gdtemp' . $g . '=' . $GDB . ':temp:LAST';
    push @gdata, 'LINE2:gdtemp' . $g . $gpucolor[$g] . ':GPU' . $g;
  }
  RRDs::graph(@gdata);
  die "graph failed: $ERR\n" if $ERR;
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
  );
  die "graph failed: $ERR\n" if $ERR;
} 

my $sumres = &sendAPIcommand("summary","");

my $mhashav = "0";my $mfoundbl = "0";my $maccept = "0";my $mreject = "0";my $mhwerrors = "0";my $mworkutil = "0";
if ($sumres =~ m/MHS\sav=(\d+\.\d+),/g) {
  $mhashav = $1 * 1000;
}
if ($sumres =~ m/Found\sBlocks=(\d+),/g) {
  $mfoundbl =$1;
}
if ($sumres =~ m/Accepted=(\d+),/g) {
  $maccept = $1;
}
if ($sumres =~ m/Rejected=(\d+),/g) {
  $mreject = $1;
}
if ($sumres =~ m/Hardware\sErrors=(\d+),/g) {
  $mhwerrors = $1;
}
if ($sumres =~ m/Work\sUtility=(\d+\.\d+),/g) {
  $mworkutil = $1;
}
RRDs::update($SDB, "--template=mhash:mwu:mshacc:mshrej:mfb:mhwe", "N:$mhashav:$mworkutil:$maccept:$mreject:$mfoundbl:$mhwerrors");
die "graph failed: $ERR\n" if $ERR;

my $mname = `hostname`;
chomp $mname;
RRDs::graph($PICPATH . "msummary.png",
 "--title","24 Hour Summary for $mname",
 "--vertical-label","Hashrate / WU",
 "--right-axis-label","Shares Acc / Rej",
 "--right-axis",".01:0",
 "--start","now-1d",
 "--end","now",
 "--width","700","--height","150",
 "--color","BACK#00000000",
 "--color","CANVAS#00000000",
 "--color","FONT$fontcolor", 
 "--border","0",
 "--font","DEFAULT:0:$fontfam",
 "--font","WATERMARK:.1:$fontfam",
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
 "TEXTALIGN:left",
 "AREA:mchash$hashcolor: Hashrate",
 "AREA:mcwu$wucolor: WU",
 "TICK:mdfb$stfcolor:-0.1: Found Block",
 "TICK:mdhwe$errorcolor:-0.1: HW Error",
 "AREA:mcshacc$acccolor: Avg. Shares Acc. / Min",
 "GPRINT:mvshacc:%2.2lf  ",
 "AREA:mccshrej$rejcolor: Avg. Shares Rej. / Min",
 "GPRINT:mvshrej:%2.2lf  ",
 );
die "graph failed: $ERR\n" if $ERR;

# Pools

my $pres = &sendAPIcommand("pools","");
my $poid; my $pdata; 
while ($pres =~ m/POOL=(\d+),(.+?)\|/g) {
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
    );
    die "graph failed: $ERR\n" if $ERR;
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
  RRDs::update($PDB, "--template=plive:pshacc:pshrej:pstale:prfail", "N:$plive:$pacc:$prej:$pstale:$prfails");
  die "graph failed: $ERR\n" if $ERR;

  RRDs::graph("-P", $PICPATH . "pool$poid.png",
   "--title","24 Hour Summary",
   "--vertical-label","Shares Acc / Rej",
   "--start","now-1d",
   "--end", "now",
   "--width","700","--height","200",
   "--color","BACK#00000000",
   "--color","CANVAS#00000000",
   "--color","FONT$fontcolor",
   "--border","1",
   "--font","DEFAULT:0:$fontfam",
   "--font","WATERMARK:4:$fontfam",
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
   "AREA:pcshacc$acccolor: Shares Accepted / Min",
   "GPRINT:pvshacc:%2.2lf  ",
   "AREA:pcstale$stfcolor: Stales / Min",
   "GPRINT:pvstale:%2.2lf  ",
   "AREA:pcshrej$rejcolor: Shares Rejected / Min",
   "GPRINT:pvshrej:%2.2lf  ",
   "TICK:pdrfail$errorcolor:-0.1: Remote Failure",
   );
  die "graph failed: $ERR\n" if $ERR;
}


