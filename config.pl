#!/usr/bin/perl
# IFMI PoolManager configuration file editor. 
#    This file is part of IFMI PoolManager.
#
#    PoolManager is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.   

 use strict;
 use warnings;
 use YAML qw( DumpFile LoadFile );
 use CGI qw(:cgi-lib :standard);

my $version = "1.1.0+";
my $conffile = "/opt/ifmi/poolmanager.conf";
if (! -f $conffile) { 
  my $nconf = {
  	monitoring => {
  		monitor_temp_hi => '80',
  		monitor_temp_lo => '45',
  		monitor_load_lo => '0',
  		monitor_hash_lo => '200',
  		monitor_fan_lo => '1000',
      monitor_fan_hi => '4000',
  		monitor_reject_hi => '3',
      do_email => '0',
  	},
  	miners => {
      0 => {
    		mconfig => 'default',
        mpath => '/opt/miners/cgminer/cgminer',
    		mopts => '--api-listen --config /opt/ifmi/cgminer.conf',
  	   	savepath => '/opt/ifmi/cgminer.conf',
      },
  	},
    settings => {
      cgminer_port => '4028',
      IGNOREBAMT => '1',
      current_mconf => '0',
    },
  	display => {
  		miner_loc => 'Undisclosed Location',
  		status_css => 'default.css',
  		farmview_css => 'default.css',
  		graphcolors => 'pmgraph.colors',
  		usehashavg => '0',
      pmversion => '$version',
  	},
  	farmview => {
  		do_bcast_status => '1',
  		do_farmview => '1',
  		status_port => '54545',
  		listen_port => '54545',
      do_direct_status => '',
  	},
    email => {
      smtp_to => 'root@localhost', 
      smtp_host => 'localhost',
      smtp_from => 'poolmanager@localhost',
      smtp_port => '25',
      smtp_tls => '1',
      smtp_ssl => '1',
      smtp_auth_user => '',
      smtp_auth_pass => '',
      smtp_min_wait => '300',
    },
    aliases => {
      0 => { url => '', alias => '' }, 
    }

  };
  DumpFile($conffile, $nconf); 
}

# Take care of business
my $conferror = 0; my $mailerror = "";
my $mconf = LoadFile( $conffile );
if (-o $conffile) {
  our %in;
  if (&ReadParse(%in)) {
    my $nht = $in{'temphi'};
    if($nht ne "") {
      $nht = "80" if (! ($nht =~ m/^\d+?$/));    
      $mconf->{monitoring}->{monitor_temp_hi} = $nht;
    }
    my $nlt = $in{'templo'};
    if($nlt ne "") {
      $nlt = "45" if (! ($nlt =~ m/^\d+?$/));
      $mconf->{monitoring}->{monitor_temp_lo} = $nlt;
    }
    my $nll = $in{'loadlo'};
    if($nll ne "") {
      $nll = "10" if (! ($nll =~ m/^\d+?$/));
      $mconf->{monitoring}->{monitor_load_lo} = $nll; 
    }
    my $nhl = $in{'hashlo'};
    if($nhl ne "") {
      $nhl = "200" if (! ($nhl =~ m/^\d+?$/));
      $mconf->{monitoring}->{monitor_hash_lo} = $nhl;
    }
    my $nfl = $in{'fanlo'};
    if($nfl ne "") {
      $nfl = "1000" if (! ($nfl =~ m/^\d+?$/));
      $mconf->{monitoring}->{monitor_fan_lo} = $nfl;
    }
    my $nfh = $in{'fanhi'};
    if($nfh ne "") {
      $nfh = "4000" if (! ($nfh =~ m/^\d+?$/));
      $mconf->{monitoring}->{monitor_fan_hi} = $nfh;
    }
    my $nrh = $in{'rejhi'};
    if($nrh ne "") {
      $nrh = "3" if (! ($nrh =~ m/^(\d+)?\.?\d+?$/));
      $mconf->{monitoring}->{monitor_reject_hi} = $nrh;
    }
    my $doe = $in{'emaildo'};
    $mconf->{monitoring}->{do_email} = $doe if($doe ne "");

    my $ncmc = $in{'setmconf'};
    $mconf->{settings}->{current_mconf} = $ncmc if ($ncmc ne "");

    my $nmconfig = $in{'nmconfig'};
    if ($nmconfig ne "") {
      my $ncname = $in{'cnmcname'}; 
      if (($ncname ne "") && ($ncname ne $nmconfig)) {
        my $newa = (keys %{$mconf->{miners}}); $newa++; 
        $mconf->{miners}->{$newa}->{mconfig} = $ncname;
        my $nmp = $in{'nmp'};
        $mconf->{miners}->{$newa}->{mpath} = $nmp;
        my $nmo = $in{'nmo'};
        $nmo = "--api-listen --config /opt/ifmi/cgminer.conf" if ($nmo eq "");
        $mconf->{miners}->{$newa}->{mopts} = $nmo;
        my $nsp = $in{'nsp'};
        $nsp = "/opt/ifmi/cgminer.conf" if ($nsp eq "");
        $mconf->{miners}->{$newa}->{savepath} = $nsp;
        $mconf->{settings}->{current_mconf} = $newa;
      } else { 
        for (keys %{$mconf->{miners}}) {
          if ($nmconfig eq $mconf->{miners}->{$_}->{mconfig}) {
            my $nmp = $in{'nmp'};
            $mconf->{miners}->{$_}->{mpath} = $nmp if ($nmp ne "");
            my $nmo = $in{'nmo'};
            $mconf->{miners}->{$_}->{mopts} = $nmo if ($nmo ne "");
            my $nsp = $in{'nsp'};
            $mconf->{miners}->{$_}->{savepath} = $nsp if ($nsp ne "");
          } 
        }
      }  
      $nmconfig = ""; $ncname = "";
    }

    my $mdel = $in{'deletem'};
    if ($mdel ne "") {
      if ($mdel != 0) {
        delete $mconf->{miners}->{$mdel};
        $mconf->{settings}->{current_mconf} = 0;
      }
    }

    my $nap = $in{'nap'};
    if($nap ne "") {
      $nap = "4028" if (! ($nap =~ m/^\d+?$/));    
      $mconf->{settings}->{cgminer_port} = $nap;
    }
    my $ibamt = $in{'ibamt'};
    $mconf->{settings}->{IGNOREBAMT} = $ibamt if($ibamt ne "");

    my $nml = $in{'nml'};
    $mconf->{display}->{miner_loc} = $nml if($nml ne "");
    my $nscss = $in{'scss'};
    $mconf->{display}->{status_css} = $nscss if($nscss ne "");
    my $nfcss = $in{'fcss'};
    if($nfcss ne "") {
      $mconf->{display}->{farmview_css} = $nfcss;
      `touch /tmp/rfv`;
    }
    my $ngcf = $in{'gcf'};
    $mconf->{display}->{graphcolors} = $ngcf if($ngcf ne "");
    my $nha = $in{'hashavg'};
    $mconf->{display}->{usehashavg} = $nha if($nha ne "");
    my $nbcast = $in{'bcast'};
    $mconf->{display}->{pm_version} = $version if ($mconf->{display}->{pm_version} eq "");

    $mconf->{farmview}->{do_bcast_status} = $nbcast if($nbcast ne "");
    my $nbp = $in{'nbp'};
    if($nbp ne "") {
      $nbp = "54545" if (! ($nbp =~ m/^\d+?$/));    
      $mconf->{farmview}->{status_port} = $nbp;
    }
    my $nfarmview = $in{'farmview'};
    $mconf->{farmview}->{do_farmview} = $nfarmview if($nfarmview ne "");
    my $nlp = $in{'nlp'};
    if($nlp ne "") {
      $nlp = "54545" if (! ($nlp =~ m/^\d+?$/));    
      $mconf->{farmview}->{listen_port} = $nlp;
      `touch /tmp/rfv`;
    }
    my $dds = $in{'dds'};
    $mconf->{farmview}->{do_direct_status} = $dds if($dds ne "");

    my $nst = $in{'mailto'};
    $mconf->{email}->{smtp_to} = $nst if ($nst ne "");
    my $nsf = $in{'mailfrom'};
    $mconf->{email}->{smtp_from} = $nsf if ($nsf ne "");
    my $nsh = $in{'mailhost'};
    $mconf->{email}->{smtp_host} = $nsh if ($nsh ne "");
    my $nsmp = $in{'mailport'};
    if ($nsmp ne "") {
      $nsmp = "25" if (! ($nsmp =~ m/^\d+?$/));
      $mconf->{email}->{smtp_port} = $nsmp;
    }
    my $nssl = $in{'mailssl'};
    $mconf->{email}->{smtp_ssl} = $nssl if ($nssl ne "");
    my $ntls = $in{'mailtls'};
    $mconf->{email}->{smtp_tls} = $ntls if ($ntls ne "");
    my $nsau = $in{'authuser'};
    $mconf->{email}->{smtp_auth_user} = $nsau if ($nsau ne "");
    my $nsap = $in{'authpass'};
    $mconf->{email}->{smtp_auth_pass} = $nsap if ($nsap ne "");
    my $nmw = $in{'mailwait'};
    if ($nmw ne "") {
      $nmw = "5" if (! ($nmw =~ m/^\d+?$/));
      $nmw = $nmw * 60; 
      $mconf->{email}->{smtp_min_wait} = $nmw;
    }
    my $se = $in{'sendemail'};
    if ($se ne "") {
      require '/opt/ifmi/pmnotify.pl';
      my $currsettings = "Email Settings:\n";
      $currsettings .= "- Email To: " . $mconf->{email}->{smtp_to} . "\n";
      $currsettings .= "- Email From: " . $mconf->{email}->{smtp_from} . "\n";
      $currsettings .= "- SMTP Host: " . $mconf->{email}->{smtp_host} . "\n";
      $currsettings .= "- SMTP port: " . $mconf->{email}->{smtp_port} . "\n";
      $currsettings .= "- Email Frequency: " . $mconf->{email}->{smtp_min_wait} / 60 . "minutes\n";
      $currsettings .= "- Auth User: " . $mconf->{email}->{smtp_auth_user} . "\n";
      $currsettings .= "\nMonitoring Settings: \n";
      $currsettings .= "- High Temp: " . $mconf->{monitoring}->{monitor_temp_hi} . "C\n"; 
      $currsettings .= "- Low Temp: " . $mconf->{monitoring}->{monitor_temp_lo} . "C\n"; 
      $currsettings .= "- High Fanspeed: " . $mconf->{monitoring}->{monitor_fan_hi} . "RPM\n"; 
      $currsettings .= "- Low Fanspeed: " . $mconf->{monitoring}->{monitor_fan_lo} . "RPM\n"; 
      $currsettings .= "- Low Load: " . $mconf->{monitoring}->{monitor_load_lo} . "\n"; 
      $currsettings .= "- Low Hashrate: " . $mconf->{monitoring}->{monitor_hash_lo} . "Kh/s\n"; 
      $currsettings .= "- High Reject Rate: " . $mconf->{monitoring}->{monitor_reject_hi} . "%\n"; 
      
      $mailerror = &sendAnEmail("TEST",$currsettings);
  }
      
    DumpFile($conffile, $mconf); 

    my $cgraphs = $in{'cgraphs'};
    if ($cgraphs ne "") {
      `/usr/bin/touch /tmp/cleargraphs.flag`;
      $cgraphs = "";
    }
  }
} else { 
  $conferror = 1; 
}

# Carry on
print header();
my $miner_name = `hostname`;
chomp $miner_name;
print start_html( -title=>'PM - ' . $miner_name . ' - Settings',
				  -style=>{-src=>'/IFMI/themes/' . $mconf->{display}->{status_css}} );

print "<div id='content'><table class=settingspage>";
print "<tr><td colspan=2 align=center>";
print "<table class=title><tr><td class=bigger>PoolManager Configuration for $miner_name</td><tr>";
if ($mailerror ne "") {
  if ($mailerror =~ m/success/i) {
    print "<tr><td colspan=2 bgcolor='green'>Test Email Sent Successfully</td><tr>";
  } elsif ($mailerror =~ m/^(.+)/) {
    my $errmsg = $1;
    print "<tr><td class=error colspan=2>$errmsg</td><tr>";
  }
}
if ($conferror == 1) {
  print "<tr><td class=error colspan=2>PoolManager cannot write to its config!";
  print "<br>Please ensure /opt/ifmi/poolmanager.conf is owned by the webserver user.</td><tr>";
}
print "</table><br></td></tr>";
print "<tr><td colspan=2 align=center>";


print "<table class=settings><tr><td class=header>Miner Profile</td><td class=header>";
my $currentm = $mconf->{settings}->{current_mconf};
my $currname = $mconf->{miners}->{$currentm}->{mconfig};
print "<form name=deletem method=post>$currname <input type='submit' value='Delete'>";
#my $delminer = $mconf->{miners}->{$currentm};
print "<input type='hidden' name='deletem' value='$currentm'></form>";
print "</td><td class=header>";
print "<form name=currentm method=post><select name=setmconf>";
for (keys %{$mconf->{miners}}) {
  my $mname = $mconf->{miners}->{$_}->{mconfig};
  if ($currentm eq $_) {
    print "<option value=$_ selected>$mname</option>";
  } else { 
    print "<option value=$_>$mname</option>";
  }
}
print "<input type='submit' value='Select'>";
print "</select></form>";

print "<td class=header><form name=msettings method=post>";
print "<input type='submit' value='Update'>";
print "<input type='hidden' name='nmconfig' value='$currname'> ";
print " <input type='text' placeholder='enter name for new profile' name='cnmcname'></td><tr>";
my $miner_path = $mconf->{miners}->{$currentm}->{mpath};
print "<tr><td>Miner Path</td><td colspan=2>$miner_path</td>";
print "<td><input type='text' size='45' placeholder='/path/to/miner' name='nmp'></td></tr>";
my $miner_opts = $mconf->{miners}->{$currentm}->{mopts};
print "<tr><td>Miner Options</td><td colspan=2>$miner_opts</td>";
print "<td><input type='text' size='45' placeholder='--api-listen --config /etc/bamt/cgminer.conf' name='nmo'></td></tr>";
my $savepath = $mconf->{miners}->{$currentm}->{savepath}; 
print "<tr><td>Miner Config<br>Save Path</td>";
print "<td colspan=2>$savepath<br><i><small>Changes to the miner config are saved here</small></i></td>";
print "<td><input type='text' size='45' placeholder='/opt/ifmi/cgminer.conf' name='nsp'>";
if ($savepath eq "/opt/ifmi/cgminer.conf") {
 print "<br><i><small>The default is probably not what you want.</small></i>";
}
print "</form></td></tr>";
print "</table><br>";

print "<tr><td colspan=2 align=center>";
print "<form name=miscsettings method=post>";
print "<table class=settings><tr><td colspan=2 class=header>Misc. Miner Settings</td>";
print "<td class=header><input type='submit' value='Save'></td><tr>";
my $minerport = $mconf->{settings}->{cgminer_port};
print "<tr><td>API port</td><td><i>Defaults to 4028 if unset</i></td>";
print "<td>$minerport <input type='text' size='4' placeholder='4028' name='nap'></td></tr>";
my $ibamt = $mconf->{settings}->{IGNOREBAMT};
if (-d "/opt/bamt/") {
  print "<tr><td>Ignore BAMT</td>";
  print "<td><i>Start miner using the above, instead of 'mine start'?</i></td>";
  if ($ibamt==1) {
    print "<td><input type='radio' name='ibamt' value=1 checked>Yes ";
    print "<input type='radio' name='ibamt' value=0>No </td></tr>";
  } else { 
    print "<td><input type='radio' name='ibamt' value=1>Yes ";
    print "<input type='radio' name='ibamt' value=0 checked>No </td></tr>"; 
  }
}
print "</table></form><br>";

print "</td></tr><tr><td rowspan=2 align=center valign=top>";
print "<form name=monitoring method=post>";
print "<table class=monitor><tr><td colspan=2 class=header>Monitoring Settings</td>";
print "<td class=header><input type='submit' value='Save'></td><tr>";
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
my $fanhi = $mconf->{monitoring}->{monitor_fan_hi};
print "<tr><td>High Fanspeed</td><td>$fanhi RPM</td>";
print "<td><input type='text' size='4' placeholder='4000' name='fanhi'></td></tr>";
my $emaildo = $mconf->{monitoring}->{do_email};
print "<tr><td>Send Email</td>";
if ($emaildo==1) {
  print "<td colspan=2><input type='radio' name='emaildo' value=1 checked>Yes ";
  print "<input type='radio' name='emaildo' value=0>No </td></tr>";
} else { 
  print "<td colspan=2><input type='radio' name='emaildo' value=1>Yes ";
  print "<input type='radio' name='emaildo' value=0 checked>No </td></tr>"; 
}

if ($emaildo==1) {
  my $mailto = $mconf->{email}->{smtp_to};
  print "<tr><td>Email To:</td><td>$mailto</td>";
  print "<td><input type='text' placeholder='user\@email.com' name='mailto'></td></tr>";
  my $mailfrom = $mconf->{email}->{smtp_from};
  print "<tr><td>Email From:</td><td>$mailfrom</td>";
  print "<td><input type='text' placeholder='poolmanager\@email.com' name='mailfrom'></td></tr>";
  my $mailhost = $mconf->{email}->{smtp_host};
  print "<tr><td>SMTP Host</td><td>$mailhost</td>";
  print "<td><input type='text' placeholder='smtp.email.com' name='mailhost'></td></tr>";
  my $mailport = $mconf->{email}->{smtp_port};
  print "<tr><td>SMTP Port</td><td>$mailport</td>";
  print "<td><input type='text' size='5' placeholder='587' name='mailport'></td></tr>";
  my $mailwait = ($mconf->{email}->{smtp_min_wait} / 60);
  print "<tr><td>Email Frequency</td><td>$mailwait minutes</td>";
  print "<td><input type='text' size='5' placeholder='5' name='mailwait'></td></tr>";
  my $mailssl = $mconf->{email}->{smtp_ssl};
  print "<tr><td>Use SSL?</td>";
  if ($mailssl==1) {
    print "<td colspan=2><input type='radio' name='mailssl' value=1 checked>Yes ";
    print "<input type='radio' name='mailssl' value=0>No </td></tr>";
    my $authuser = $mconf->{email}->{smtp_auth_user};
    print "<tr><td>Auth User</td><td>$authuser</td>";
    print "<td><input type='text' placeholder='mailuser' name='authuser'></td></tr>";
    my $authpass = $mconf->{email}->{smtp_auth_pass};
    my $authshow = "*******" if ($authpass ne "");
    print "<tr><td>Auth Pass</td><td>$authshow</td>";
    print "<td><input type='password' placeholder='mailpassword' name='authpass' autocomplete='off'></td></tr>";
    my $mailtls = $mconf->{email}->{smtp_tls};
    print "<tr><td>Use TLS?</td>";
    if ($mailtls==1) {
      print "<td colspan=2><input type='radio' name='mailtls' value=1 checked>Yes ";
      print "<input type='radio' name='mailtls' value=0>No </td></tr>";
    } else { 
      print "<td colspan=2><input type='radio' name='mailtls' value=1>Yes ";
      print "<input type='radio' name='mailtls' value=0 checked>No </td></tr>"; 
    }
  } else { 
    print "<td colspan=2><input type='radio' name='mailssl' value=1>Yes ";
    print "<input type='radio' name='mailssl' value=0 checked>No </td></tr>"; 
  }
  print "</form><form name=testemail method=post><tr><td colspan=2>Send a Test Email</td><td>";
  print "<input type=submit name='sendemail' value='Send' method=post></td></tr></form>";
}
print "</table><br>";

print "</td><td align=center>";

print "<form name=farmview method=post>";
print "<table class=farmview><tr><td colspan=2 class=header>Farmview Settings</td>";
print "<td class=header><input type='submit' value='Save'></td><tr>";
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
my $directip = $mconf->{farmview}->{do_direct_status};
print "<tr><td>FarmView IP</td>";
print "<td><i>Only needed if FV is not local</i></td>";
print "<td>$directip <input type='text' size='15' placeholder='192.168.5.100' name='dds'></td></tr>";
my $dfarm = $mconf->{farmview}->{do_farmview};
print "<tr><td>FarmView</td>";
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
print "<td><i>Port FV should listen on<br><small>FV will restart if changed</small></i></td>";
print "<td>$lport <input type='text' size='5' placeholder='54545' name='nlp'></td></tr>";
print "</table></form>";

print "</td></tr><tr><td align=center>";

print "<form name=display method=post>";
print "<table class=display><tr><td colspan=2 class=header>Display Settings</td>";
print "<td class=header><input type='submit' value='Save'></td><tr>";
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
print "<tr><td>Farmview CSS</td><td>$farm_css<br><i><small>FV will restart if changed</small></i></td>";
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
  print "<td><i>wait for it..</i></td>";
  print "<td><input type='hidden' name='cgraphs' value='cgraphs'><button type='submit'>Clear</button></td></tr>";
  print "</table></form>";

print "</td></tr>";

print "<tr><td colspan=2><a href='status.pl'>Back to node page</a></td></tr>";

print "</table></div>";
print "</body></html>";
