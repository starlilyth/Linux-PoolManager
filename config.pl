#!/usr/bin/perl
 use strict;
 use warnings;
 use YAML qw( DumpFile LoadFile );
 use CGI qw(:cgi-lib :standard);

my $conffile = "/opt/ifmi/poolmanager.conf";
my $mconf = LoadFile( $conffile );

# Take care of business
our %in;
if (&ReadParse(%in)) {
  my $nht = $in{'temphi'};
  $mconf->{monitoring}->{monitor_temp_hi} = $nht if($nht ne"");
  my $nlt = $in{'templo'};
  $mconf->{monitoring}->{monitor_temp_lo} = $nlt if($nlt ne "");
  my $nll = $in{'loadlo'};
  $mconf->{monitoring}->{monitor_load_lo} = $nll if($nll ne ""); 
  my $nhl = $in{'hashlo'};
  $mconf->{monitoring}->{monitor_hash_lo} = $nhl if($nhl ne "");
  my $nfl = $in{'fanlo'};
  $mconf->{monitoring}->{monitor_fan_lo} = $nfl if($nfl ne "");
  my $nrh = $in{'rejhi'};
  $mconf->{monitoring}->{monitor_reject_hi} = $nrh if($nrh ne "");

  my $nmp = $in{'nmp'};
  $mconf->{settings}->{cgminer_path} = $nmp if($nmp ne "");
  my $nmo = $in{'nmo'};
  $mconf->{settings}->{cgminer_opts} = $nmo if($nmo ne "");
  my $nsp = $in{'nsp'};
  $mconf->{settings}->{savepath} = $nsp if($nsp ne "");
  my $ibamt = $in{'ibamt'};
  $mconf->{settings}->{IGNOREBAMT} = $ibamt if($ibamt ne "");

  my $nml = $in{'nml'};
  $mconf->{display}->{miner_loc} = $nml if($nml ne "");
  my $nscss = $in{'scss'};
  $mconf->{display}->{status_css} = $nscss if($nscss ne "");
  my $nfcss = $in{'fcss'};
  $mconf->{display}->{farmview_css} = $nfcss if($nfcss ne "");
  my $ngcf = $in{'gcf'};
  $mconf->{display}->{graphcolors} = $ngcf if($ngcf ne "");
  my $nha = $in{'hashavg'};
  $mconf->{display}->{usehashavg} = $nha if($nha ne "");

  my $nbcast = $in{'bcast'};
  $mconf->{farmview}->{do_bcast_status} = $nbcast if($nbcast ne "");
  my $nbp = $in{'nbp'};
  $mconf->{farmview}->{status_port} = $nbp if($nbp ne "");
  my $nfarmview = $in{'farmview'};
  $mconf->{farmview}->{do_farmview} = $nfarmview if($nfarmview ne "");
  my $nlp = $in{'nlp'};
  $mconf->{farmview}->{listen_port} = $nlp if($nlp ne "");
  DumpFile($conffile, $mconf); 

  my $cgraphs = $in{'cgraphs'};
  if ($cgraphs ne "") {
    exec `/usr/bin/touch /tmp/cleargraphs.flag`;
    $cgraphs = "";
  }
}

# Carry on
print header();
my $miner_name = `hostname`;
chomp $miner_name;
print start_html( -title=>'PoolManager - ' . $miner_name . ' config',
				  -style=>{-src=>'/IFMI/themes/' . $mconf->{display}->{status_css}} );

print "<div id='content'><table>";
print "<tr><td colspan=2>";
print "<table class=title><tr><td class=bigger>PoolManager Configuration for $miner_name</td><tr></table><br>";
print "</td></tr>";

print "<tr><td colspan=2>";
print "<form name=settings method=post>";
print "<table class=settings><tr><td colspan=2 class=header>Miner Settings</td>";
print "<td><input type='submit' value='Save'></td><tr>";
my $miner_path = $mconf->{settings}->{cgminer_path};
print "<tr><td>Miner Path</td><td>$miner_path</td>";
print "<td><input type='text' size='45' placeholder='/path/to/miner' name='nmp'></td></tr>";
my $miner_opts = $mconf->{settings}->{cgminer_opts};
print "<tr><td>Miner Options</td><td>$miner_opts</td>";
print "<td><input type='text' size='45' placeholder='--api-listen --config /etc/bamt/cgminer.conf' name='nmo'></td></tr>";
my $savepath = $mconf->{settings}->{savepath}; 
print "<tr><td>Configuration Path</td><td>$savepath</td>";
print "<td><input type='text' size='45' placeholder='/opt/ifmi/cgminer.conf' name='nsp'></td></tr>";
my $ibamt = $mconf->{settings}->{IGNOREBAMT};
print "<tr><td>Ignore BAMT</td>";
print "<td><i>Start/stop the miner directly, instead of 'mine stop/start'?</i></td>";
if ($ibamt==1) {
  print "<td><input type='radio' name='ibamt' value=1 checked>Yes ";
  print "<input type='radio' name='ibamt' value=0>No </td></tr>";
} else { 
  print "<td><input type='radio' name='ibamt' value=1>Yes ";
  print "<input type='radio' name='ibamt' value=0 checked>No </td></tr>";
}
print "</table></form><br>";

print "</td></tr><tr><td rowspan=2>";

print "<form name=monitoring method=post>";
print "<table class=monitor><tr><td colspan=2 class=header>Monitoring Settings</td>";
print "<td><input type='submit' value='Save'></td><tr>";
my $temphi = $mconf->{monitoring}->{monitor_temp_hi};
print "<tr><td>High Temp</td><td>$temphi C</td>";
print "<td><input type='text' size='2' placeholder='80' name='temphi'></td></tr>";
my $templo = $mconf->{monitoring}->{monitor_temp_lo};
print "<tr><td>Low Temp</td><td>$templo C</td>";
print "<td><input type='text' size='2' placeholder='45' name='templo'></td></tr>";
my $hashlo = $mconf->{monitoring}->{monitor_hash_lo};
print "<tr><td>Low Hashrate</td><td>$hashlo Kh/s</td>";
print "<td><input type='text' size='3' placeholder='200' name='hashlo'></td></tr>";
my $loadlo = $mconf->{monitoring}->{monitor_load_lo};
print "<tr><td>Low Load</td><td>$loadlo</td>";
print "<td><input type='text' size='2' placeholder='0' name='loadlo'></td></tr>";
my $rejhi = $mconf->{monitoring}->{monitor_reject_hi};
print "<tr><td>High Reject Rate</td><td>$rejhi%</td>";
print "<td><input type='text' size='2' placeholder='3' name='rejhi'></td></tr>";
my $fanlo = $mconf->{monitoring}->{monitor_fan_lo};
print "<tr><td>Low Fanspeed</td><td>$fanlo RPM</td>";
print "<td><input type='text' size='4' placeholder='1000' name='fanlo'></td></tr>";
print "</table></form><br>";

print "</td><td>";

print "<form name=farmview method=post>";
print "<table class=farmview><tr><td colspan=2 class=header>Farmview Settings</td>";
print "<td><input type='submit' value='Save'></td><tr>";
my $bcast = $mconf->{farmview}->{do_bcast_status};
print "<tr><td>Broadcast Status</td>";
print "<td><i>Send Node Status?</i></td>";
if ($bcast==1) {
  print "<td><input type='radio' value=1 name='bcast' checked>Yes";
  print "<input type='radio' value=0 name='bcast'>No</td>";
} else { 
  print "<td><input type='radio' value=1 name='bcast'>Yes";
  print "<input type='radio' value=0 name='bcast' checked>No</td>";
}
print "</tr>";
my $statport = $mconf->{farmview}->{status_port};
print "<tr><td>Broadcast Port</td>";
print "<td><i>Port to send status on</i></td>";
print "<td>$statport <input type='text' size='5' placeholder='54545' name='nbp'></td></tr>";
my $dfarm = $mconf->{farmview}->{do_farmview};
print "<tr><td>Farmview</td>";
print "<td><i>Run FarmView on this node?</i></td>";
if ($dfarm==1) {
  print "<td><input type='radio' value='1' name='farmview' checked>Yes";
  print "<input type='radio' value='0' name='farmview'>No</td>";
} else { 
  print "<td><input type='radio' value='1' name='farmview'>Yes";
  print "<input type='radio' value='0' name='farmview' checked>No</td>";
}
print "</tr>";
my $lport = $mconf->{farmview}->{listen_port};
print "<tr><td>Listen Port</td>";
print "<td><i>Port to listen for statuses on</i></td>";
print "<td>$lport <input type='text' size='5' placeholder='54545' name='nlp'></td></tr>";
print "</table></form>";

print "</td></tr><tr><td>";

print "<form name=display method=post>";
print "<table class=display><tr><td colspan=2 class=header>Display Settings</td>";
print "<td><input type='submit' value='Save'></td><tr>";
my $miner_loc = $mconf->{display}->{miner_loc};
print "<tr><td>Miner Location</td><td>$miner_loc</td>";
print "<td><input type='text' placeholder='Location text' name='nml'></td></tr>";

my $status_css = $mconf->{display}->{status_css};
print "<tr><td>Status CSS</td><td>$status_css</td>";
print "<td><select name=scss>";
my @csslist = glob("/var/www/IFMI/themes/*.css");
    foreach my $file (@csslist) {
    	$file =~ s/\/var\/www\/IFMI\/themes\///;
    	if ("$file" eq "$status_css") {
          print "<option value=$file selected>$file</option>";
        } else { 
          print "<option value=$file>$file</option>";
        }
    }
print "</select></td></tr>";
my $farm_css = $mconf->{display}->{farmview_css}; 
print "<tr><td>Farmview CSS</td><td>$farm_css</td>";
print "<td><select name=fcss>";
my @fcsslist = glob("/var/www/IFMI/themes/*.css");
    foreach my $file (@fcsslist) {
       	$file =~ s/\/var\/www\/IFMI\/themes\///;
       	if ("$file" eq "$farm_css") {
          print "<option value=$file selected>$file</option>";
        } else { 
          print "<option value=$file>$file</option>";
        }
    }
print "</select></td></tr>";
my $gcolors = $mconf->{display}->{graphcolors};
print "<tr><td>Graph Colors File</td><td>$gcolors</td>";
print "<td><select name=gcf>";
my @colorslist = glob("/var/www/IFMI/themes/*.colors");
    foreach my $file (@colorslist) {
    	$file =~ s/\/var\/www\/IFMI\/themes\///;
    	if ("$file" eq "$gcolors") {
          print "<option value=$file selected>$file</option>";
 		}else { 
          print "<option value=$file>$file</option>";
 		}
    }
print "</select></td></tr>";
my $hashavg = $mconf->{display}->{usehashavg};
print "<tr><td>Hashrate Display</td>";
print "<td><i>5sec average, or Overall (old style)</i></td>";
if ($hashavg==1) {
  print "<td><input type='radio' name='hashavg' value=0>5 sec";
  print "<input type='radio' name='hashavg' value=1 checked>Overall</td></tr>";
} else { 
  print "<td><input type='radio' name='hashavg' value=0 checked>5 sec";
  print "<input type='radio' name='hashavg' value=1>Overall</td></tr></form>";
}
  print "<form><tr><td>Clear All Graphs</td>";
  print "<td><i>just wait for it..</i></td>";
  print "<td><input type='hidden' name='cgraphs' value='cgraphs'><button type='submit'>Clear</button></td></tr>";
  print "</table></form>";

print "</td></tr>";

print "<tr><td colspan=2><a href='status.pl'>Back to node page</a></td></tr>";

print "</table></div>";
print "</body></html>";
