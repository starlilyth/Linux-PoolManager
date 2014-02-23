#!/usr/bin/perl
use CGI qw(:cgi-lib :standard);
use feature qw(switch);
use Data::Dumper;

require '/opt/ifmi/pm-common.pl';

# Take care of business
&ReadParse(%in);

my $zreq = $in{'zero'};
if ($zreq ne "") {
  &zeroStats;
  $zreq = "";
}

my $preq = $in{'swpool'};
if ($preq ne "") {
  &switchPool($preq);
  $preq = "";
}

my $apooln = $in{'npoolurl'};
my $apoolu = $in{'npooluser'};
my $apoolp = $in{'npoolpw'};
if ($apooln ne "") {
  my $pmatch = 0;
  my @pools = &getCGMinerPools(1);
  if (@pools) {
    for (my $i=0;$i<@pools;$i++) {
      $pname = ${@pools[$i]}{'url'};
      $pmatch++ if ($pname eq $apooln);
    }
  }
  if ($pmatch eq 0) {
    &addPool($apooln, $apoolu, $apoolp);
    &saveConfig();
    $apooln = ""; $apoolu = ""; $apoolp = "";
  } 
}
my $dpool = $in{'delpool'};
if ($dpool ne "") {
  &delPool($dpool);
  &saveConfig();
  $dpool = "";
}

my $cgraphs = $in{'cgraphs'};
if ($cgraphs ne "") {
  exec `/usr/bin/touch /tmp/cleargraphs.flag`;
  $cgraphs = "";
}

my $mstop = $in{'mstop'};
if ($mstop eq "stop") { 
  $status = `echo $in{'ptext'} | sudo -S /opt/ifmi/mcontrol stop`;
  $mstop = ""; 
}

my $mstart = $in{'mstart'};
if ($mstart eq "start") { 
  my $sup = $in{'ptext'};
  $status = `echo $in{'ptext'} | sudo -S /opt/ifmi/mcontrol start`;
  $mstart = ""; 
}

my $reboot = $in{'reboot'};
if ($reboot eq "reboot") { 
  $status = `echo $in{'ptext'} | sudo -S /sbin/coldreboot`;
}  

# Someday, maybe.
my $qval = $in{'qval'};
if ($qval ne "") {
  my $qpool = $in{'qpool'};
  &quotaPool($qpool, $qval);
  $qval = ""; $qpool = "";
}
my $qreset = $in{'qreset'};
if ($qreset eq "reset") {
  my @pools = &getCGMinerPools(1);
  for (my $i=0;$i<@pools;$i++) {
    &quotaPool($i, "1");
  }
  $qreset = "";
}

# Now carry on
our $conf = &getConfig;
%conf = %{$conf};

$q=CGI->new();

$showgpu = -1;
$showpool = -1;
$showminer = -1;

if (defined($q->param('gpu')))
{
	$showgpu = $q->param('gpu');
}
if (defined($q->param('pool')))
{
	$showpool = $q->param('pool');
}
if (defined($q->param('miner')))
{
	$showminer = $q->param('miner');
}

my $url = "?";

if ($showgpu > -1)
{
	$url .= "gpu=$showgpu&";
}
if ($showpool > -1)
{
	$url .= "pool=$showpool&";
}
if ($showminer > -1)
{
	$url .= "miner=$showminer&";
}

print header;
if ($url eq "?")
{
	print start_html( -title=>'PoolManager - ' . $conf{'settings'}{'miner_id'} . ' status', -style=>{-src=>'/IFMI/status.css'},  -head=>$q->meta({-http_equiv=>'REFRESH',-content=>'30'})  );
}
else
{
	$url .= "tok=1";
	print start_html( -title=>'PoolManager - ' . $conf{'settings'}{'miner_id'} . ' status', -style=>{-src=>'/IFMI/status.css'},  -head=>$q->meta({-http_equiv=>'REFRESH',-content=>'30; url=' . $url })  );

}

# pull info
my $version = &getCGMinerVersion;
my $ispriv = &CGMinerIsPriv; 
my @gpus = &getFreshGPUData(1);
my @pools = &getCGMinerPools(1);
my @summary = &getCGMinerSummary;
my $UHOH = "false";
$UHOH = "true" if (!(@pools) && !(@summary) && !(@gpus)); 

# do GPUs
my $gput = "";
my $problems = 0;
my $okgpus = 0;
my $problemgpus = 0;
my @nodemsg;
my @gpumsg;

$g1put .= "<TABLE><TR class='ghdr'><TD class='ghdr'>GPU</TD>";
$g1put .= "<TD class='ghdr'>Status</TD>";
$g1put .= "<TD class='ghdr'>Temp</TD>";
$g1put .= "<TD class='ghdr'>Fan</TD>";
$g1put .= "<TD class='ghdr'>Rate</TD>";
$g1put .= "<TD class='ghdr'>Pool</TD>";
$g1put .= "<TD class='ghdr' colspan=2>Accept/Reject</TD>";
$g1put .= "<TD class='ghdr'>I</TD>";
$g1put .= "<TD class='ghdr'>HW</TD>";
$g1put .= "<TD class='ghdr'>Core</TD>";
$g1put .= "<TD class='ghdr'>Memory</TD>";
$g1put .= "<TD class='ghdr'>Power</TD></tr>";

my $gsput = "";

for (my $i=0;$i<@gpus;$i++)
{
    my $gput = "";
#    my $gsput = ""; 

	if ($i == $showgpu)
	{
 		my $gpudesc = ""; 
    	my $gpudesc = $gpus[$i]{'desc'}; 
    	if ($gpudesc ne "") {
  	  		$gsput .= "<tr><td>GPU model:</td><td colspan=3>$gpudesc</td></tr>";
  		} else { 
  	  		$gsput .= "<tr><td>GPU model:</td><td colspan=3>Unknown</td></tr>";
  		}
  	}

    my $ghealth = $gpus[$i]{'status'}; 
    if ($ghealth ne "Alive") 
	{
		$problems++;
		push(@nodemsg, "GPU $i is $ghealth");
		
		if ($i == $showgpu)
		{
			push(@gpumsg, "$ghealth");
			$gsput .= "<tr><td>Status:</td><td class='error'>$ghealth</td>";	
	        $gsput .= '<td>Enabled:</td><td>' . $gpus[$i]{'enabled'} . "</td></tr>";
		}
	}
	else
	{
		if ($i == $showgpu)
		{
			$gsput .= "<tr><td>Status:</td><td>$ghealth</td>";	
	        $gsput .= "<td>Enabled:</td><td>" . $gpus[$i]{'enabled'} . "</td></tr>";
		}
		
 	}	

	if (defined($conf{settings}{monitor_temp_hi}) && ($gpus[$i]{'current_temp_0_c'} > $conf{settings}{monitor_temp_hi}))
	{
			$problems++;
			push(@nodemsg, "GPU $i is over maximum temp");
			
			if ($i == $showgpu)
			{
				push(@gpumsg, "Over maximum temp");
				$gsput .= "<tr><td>Temp:</td><td class='error'>" . sprintf("%.1f", $gpus[$i]{'current_temp_0_c'}) . 'C</td>';	
			}
			
			$gput .= "<td class='error'>";
	}
	elsif (defined($conf{settings}{monitor_temp_lo}) && ($gpus[$i]{'current_temp_0_c'} < $conf{settings}{monitor_temp_lo}))
	{
			$problems++;
			push(@nodemsg, "GPU $i is below minimum temp");

			if ($i == $showgpu)
			{
				push(@gpumsg, "Below minimum temp");
				$gsput .= "<tr><td>Temp:</td><td class='error'>" . sprintf("%.1f", $gpus[$i]{'current_temp_0_c'}) . ' C</td>';	
			}
			
			$gput .= "<td class='error'>";
	}
	else
	{
		if ($i == $showgpu)
		{
			$gsput .= "<tr><td>Temp:</td><td>" . sprintf("%.1f", $gpus[$i]{'current_temp_0_c'}) . ' C</td>';
		}
		$gput .= '<td>';
	}		
	$gput .= sprintf("%.1f", $gpus[$i]{'current_temp_0_c'}) . ' C</td>';
	
	$frpm = $gpus[$i]{'fan_rpm_c'}; $frpm = "0" if ($frpm eq "");
	if (defined($conf{settings}{monitor_fan_lo}) && $frpm < ($conf{settings}{monitor_fan_lo}) && ($frpm > 0))
	{
		$problems++;
		push(@nodemsg, "GPU $i is below minimum fan rpm");
		
		if ($i == $showgpu)
		{
			push(@gpumsg, "Below minimum fan rpm");
			$gsput .= "<td>Fan speed:</td><td class='error'>" .  $gpus[$i]{'fan_speed_c'} . '% (' . $gpus[$i]{'fan_rpm_c'}  . " rpm)</td></tr>";
		}
		
		$gput .= "<td class='error'>";
	}
	else
	{
		if ($i == $showgpu)
		{
				$gsput .= "<td>Fan speed:</td><td>" .  $gpus[$i]{'fan_speed_c'} . '% ';
				if ($frpm > 0) {
				  $gsput .= '(' . $gpus[$i]{'fan_rpm_c'}  . ' rpm)';
				}
				$gsput .= "</td></tr>";
		}
		
		$gput .= '<td>';
	}		
	$gput .= $gpus[$i]{'fan_speed_c'} . '% ';
	if ($frpm > 0) {
	  $gput .= '(' . $gpus[$i]{'fan_rpm_c'} . ')';
	}
	$gput .= '</TD>';
		
	my $ghashrate = $gpus[$i]{'hashrate'}; 
	$ghashrate = $gpus[$i]{'hashavg'} if ($ghashrate eq "");
	if (defined($conf{settings}{monitor_hash_lo}) && ($ghashrate < $conf{settings}{monitor_hash_lo}))
	{
		$problems++;
		push(@nodemsg, "GPU $i is below minimum hash rate");
		if ($i == $showgpu)
		{
			push(@gpumsg, "Below minimum hash rate");
		}	
		$gput .= "<td class='error'>";
	}
	else
	{
		$gput .= '<td>';
	}	
	$gput .= sprintf("%d", $ghashrate) . " Kh/s</TD>";


    my $poolurl = $gpus[$i]{'pool_url'};
    if ($poolurl =~ m/.+\@(.+)/) {
      $poolurl = $1;
    }	
    if ($poolurl =~ m|://\w*?\.?(\w+\.\w+:\d+)$|) {
       $shorturl = $1;
    }
 	$shorturl = "N/A" if ($shorturl eq ""); 
    if ($i == $showgpu) {
        $gsput .= "<tr><td>Pool:</td><td colspan=3>" . $poolurl  . "</td>";
    }
	$gput .= "<td>" . $shorturl . "</td>";


	my $gsha = $gpus[$i]{'shares_accepted'}; $gsha = 0 if ($gsha eq "");
	my $gshi = $gpus[$i]{'shares_invalid'}; $gshi = 0 if ($gshi eq "");
	$gput .= '<TD>' . $gsha . " / " . $gshi . '</TD>';		
	if ($gsha > 0)
	{
		my $rr = $gpus[$i]{'shares_invalid'}/($gpus[$i]{'shares_accepted'} + $gpus[$i]{'shares_invalid'})*100 ;		
		if (defined(${$conf}{settings}{monitor_reject_hi}) && ($rr > ${$conf}{settings}{monitor_reject_hi}))
		{
			$problems++;
			push(@nodemsg, "GPU $i is above maximum reject rate");
			if ($i == $showgpu)
			{
				push(@gpumsg, "Above maximum reject rate");
		        $gsput .= "<tr><td>Total MH:</td><td>" . $gpus[$i]{'total_mh'} . "</td>";
				$gsput .= "<td>Shares A/R:</td><td class='error'>" .  $gpus[$i]{'shares_accepted'} . ' / ' . $gpus[$i]{'shares_invalid'} . ' (' . sprintf("%-2.2f%", $rr) . ")</td></tr>";
			}			
			$gput .= "<td class='error'>";
		}
		else
		{
			if ($i == $showgpu)
			{
		        $gsput .= "<tr><td>Total MH:</td><td>" . $gpus[$i]{'total_mh'} . "</td>";
				$gsput .= "<td>Shares A/R:</td><td>" .  $gpus[$i]{'shares_accepted'} . ' / ' . $gpus[$i]{'shares_invalid'} . ' (' . sprintf("%-2.2f%", $rr) . ")</td></tr>";
			}			
			$gput .= '<td>';
		}		
		$gput .= sprintf("%-2.2f%", $rr);
	}
	else
	{
		if ($i == $showgpu)
		{
				$gsput .= "<tr><td>Shares A/R:</td><td>" .  $gpus[$i]{'shares_accepted'} . ' / ' . $gpus[$i]{'shares_invalid'} . "</td></tr>";
		}
		
		$gput .= '<td>N/A';
	}	
	$gput .= "</TD>";

	$gint = $gpus[$i]{'intensity'}; $gint = "0" if ($gint eq "");	
	$gput .= '<TD>' . $gint . '</td>';
	
    my $ghwe = $gpus[$i]{'hardware_errors'};	
	if ($ghwe > 0) { 
	  $problems++;
	  push(@nodemsg, "GPU $i has hardware errors");
	  if ($i == $showgpu) {
		push(@gpumsg, "Hardware errors");
	  }
	  $gpuhwe = "<td class='error'>" . $ghwe . "</td>";
	} else { 
	  $ghwe = "N/A" if ($ghwe eq ""); 
	  $gpuhwe = "<td>" . $ghwe . "</td>";
	}
    $gput .= $gpuhwe;
	
	$gccc = $gpus[$i]{'current_core_clock_c'}; $gccc = "0" if ($gccc eq "");	
	$gput .= '<TD>' . $gccc . ' Mhz</td>';

	$gcmc = $gpus[$i]{'current_mem_clock_c'}; $gcmc = "0" if ($gcmc eq "");			
	$gput .= '<TD>' . $gcmc . ' Mhz</td>';

	$gccv = $gpus[$i]{'current_core_voltage_c'}; $gccv = "0" if ($gccv eq "");				
	$gput .= '<TD>' . $gccv . 'v</td>';

	$gput .= "</TR>";

	if (defined($conf{settings}{monitor_load_lo}) && ($gpus[$i]{'current_load_c'} < $conf{settings}{monitor_load_lo}))
	{
		$problems++;
		push(@nodemsg, "GPU $i is below minimum load");
		$gpuload = "<td class='error'>" . $gpus[$i]{'current_load_c'}  ."%</td>";
		push(@gpumsg, "Below minimum load");
	} else {
		$gpuload = "<td>" . $gpus[$i]{'current_load_c'}  . "%</td>";		
 	}	

	if ($i == $showgpu)
	{
		$gsput .= "<tr><td>Load:</td>" . $gpuload;

        push(@gpumsg, "GPU $i has Hardware Errors") if ($ghwe > 0);		
		$gsput .= "<td>HW Errors:</td>" . $gpuhwe . "</tr>"; 

        $gsput .= "<tr><td>Intensity:</td><td>" . $gpus[$i]{'intensity'} . "</td>";
        $gsput .= "<td>Powertune:</td><td>" . $gpus[$i]{'current_powertune_c'} . "%</td></tr>";

		$gsput .= "<tr><td>Core clock:</td><td>" . $gccc . ' Mhz</td>'; 
		$gsput .= "<td>Mem clock:</td><td>" . $gcmc . ' Mhz</td></tr>';
		$gsput .= "<tr><td>Core power:</td><td>" . $gccv . "v</td></tr>";
#        $gsput .= "<tr><td>Run time:</td><td>" . $gpus[$i]{'elapsed'} . "</td></tr>";
		$ggimg = "<br><img src='/IFMI/graphs/gpu$i.png'>";
	}
		
	my $gpuurl = "?";	

	$gpuurl .= "gpu=$i";
	
	if ($problems)
	{
		$gput = '<TR><TD class="bigger"><A href="' . $gpuurl . '">' . $i . '</TD><TD class=error><img src=/bamt/error24.png></td>' . $gput;
		$problemgpus++;
	}
	else
	{
		$gput = '<TR><TD class="bigger"><A href="' . $gpuurl . '">' . $i . '</TD><TD><img src=/bamt/ok24.png></td>' . $gput;
		$okgpus++;
	}
	$g1put .= $gput;
	$problems = 0;
}
$g1put .= "</table>";

$mcontrol .= "<table><tr>";
my $surl = "?"; $surl .= "miner=$i";
$mcontrol .= '<TD class="bigger"><A href="' . $surl . '">Miner</a></td>';
if ($version =~ m/Miner=(\d+\.\d+\.\d+),API=1\.(\d+)/) {
  	$mvers = $1; 
  	$avers = $2; 
} else { 
	$mvers = "Unknown";
	$avers = "0"; 
}
$mcontrol .= "<td>version: $mvers</td>";

if (@summary) {
  for (my $i=0;$i<@summary;$i++) {
    $melapsed = ${@summary[$i]}{'elapsed'};
    $mrunt = sprintf("%d days, %02d:%02d.%02d",(gmtime $melapsed)[7,2,1,0]);
    $mratem = ${@summary[$i]}{'hashrate'};
    $mratem = ${@summary[$i]}{'hashavg'} if ($mratem eq "");
    $minerate = sprintf("%.2f", $mratem);
    $mineacc = ${@summary[$i]}{'shares_accepted'};
    $minerej = ${@summary[$i]}{'shares_invalid'};
    $minewu = ${@summary[$i]}{'work_utility'};
    $minehe = ${@summary[$i]}{'hardware_errors'};

  	if ($showminer == $i) {
  		$getmlinv = `cat /proc/version`;
  		$mlinv = $1 if ($getmlinv =~ /version\s(.*?\s+\(.*?\))\s+\(/);
      	$msput .= "<tr><td class='big'>Linux Version:</td><td  colspan=3>" . $mlinv . "</td></tr>";
# It is unclear how relevant this information is, and it is difficult to extract. 
#  		$madlv = "1";
#      	$msput .= "<tr><td>ADL Version:</td><td>" . $madlv . "</td></tr>";
#  		$mcatv = "1";
#      	$msput .= "<tr><td>Catalyst Version:</td><td>" . $mcatv . "</td></tr>";
#   	$msdkv = "1";
#      	$msput .= "<tr><td>SDK Version:</td><td>" . $msdkv . "</td></tr>";		
      	my $nicget = `/sbin/ifconfig`; 
      	while ($nicget =~ m/(\w\w\w\w?\d)\s.+\n\s+inet addr:(\d+\.\d+\.\d+\.\d+)\s/g) {
      	  $iptxt = $2; 
		  $msput .= '<td class=big colspan=2><A href=ssh://user@' . $iptxt . '>SSH to Host</a></td></tr>';
		}
      	$msput .= "<tr><td class='big' colspan=2><a href='/cgi-bin/confedit.pl' target='_blank'>Configuration Editor</a></td></tr>";
		$msput .= "<form name='reboot' action='poolmanage.pl' method='POST'><input type='hidden' name='reboot' value='reboot'>";
		$msput .= "<tr><td></td></tr><tr><td colspan=2><input type='submit' value='Reboot' onclick='this.disabled=true;this.form.submit();' > ";
		$msput .= "<input type='password' placeholder='root password' name='ptext' required></td></tr></form>";
		$msput .= "<tr><td colspan=4><hr></td></tr>";
		$avers = " (1." . $avers . ")" if ($avers ne "");
  		$msput .= "<tr><td>Miner Version (API)</td><td colspan=3>" . $mvers . $avers . "</td></tr>";
      	$msput .= "<tr><td>Run time:</td><td>" . $mrunt . "</td>";
		if ($melapsed > 0) {  	  
		  $msput .= "<td  colspan=2><form name='mstop' action='status.pl' method='POST'><input type='hidden' name='mstop' value='stop'><input type='submit' value='Stop' onclick='this.disabled=true;this.form.submit();' > ";
		} else { 
		  $msput .= "<td  colspan=2><form name='mstart' action='status.pl' method='POST'><input type='hidden' name='mstart' value='start'><input type='submit' value='Start' onclick='this.disabled=true;this.form.submit();' > ";
		}
		$msput .= "<input type='password' placeholder='root password' name='ptext' required></form></tr>";
		$mtm = ${@summary[$i]}{'total_mh'};
		$minetm = sprintf("%.2f", $mtm); 
      	$msput .= "<tr><td>Total MH:</td><td>" . $minetm . "</td>";
		$minefb = ${@summary[$i]}{'found_blocks'};
		$minefb = 0 if ($minefb eq "");
      	$msput .= "<td>Found Blocks:</td><td>" . $minefb . "</td></tr>";
		$minegw = ${@summary[$i]}{'getworks'};
		$minegw = 0 if ($minegw eq "");
      	$msput .= "<tr><td>Getworks:</td><td>" . $minegw . "</td>";
		$minedis = ${@summary[$i]}{'discarded'};
      	$minedis = 0 if ($minedis eq "");
      	$msput .= "<td>Discarded:</td><td>" . $minedis . "</td></tr>";
		$minest = ${@summary[$i]}{'stale'};
		$minest = 0 if ($minest eq "");
      	$msput .= "<tr><td>Stale:</td><td>" . $minest . "</td>";
		$minegf = ${@summary[$i]}{'get_failures'};
		$minegf = 0 if ($minegf eq "");
      	$msput .= "<td>Get Failures:</td><td>" . $minegf . "</td></tr>";
		$minerf = ${@summary[$i]}{'remote_failures'};
		$minerf = 0 if ($minerf eq "");
      	$msput .= "<tr><td>Remote Fails:</td><td>" . $minerf . "</td>";
		$minenb = ${@summary[$i]}{'network_blocks'};
		$minenb = 0 if ($minenb eq "");
      	$msput .= "<td>Network Blocks:</td><td>" . $minenb . "</td></tr>";
      	$mdia = ${@summary[$i]}{'diff_accepted'};
		$minedia = sprintf("%d", $mdia);
      	$msput .= "<tr><td>Diff Accepted:</td><td>" . $minedia . "</td>";
      	$mdir = ${@summary[$i]}{'diff_rejected'};
		$minedir = sprintf("%d", $mdir);
      	$msput .= "<td>Diff Rejected:</td><td>" . $minedir . "</td></tr>";
      	$mds = ${@summary[$i]}{'diff_stale'};
		$mineds = sprintf("%d", $mds);
      	$msput .= "<tr><td>Difficulty Stale:</td><td>" . $mineds . "</td>";
		$minebs = ${@summary[$i]}{'best_share'};
		$minebs = 0 if ($minebs eq "");
      	$msput .= "<td>Best Share:</td><td>" . $minebs . "</td></tr>";
 		$msput .= "<tr><td colspan=4><hr></td></tr>";
 		$msput .= "<tr><td>Clear All Graphs</td><td>";
	    $msput .= "<form name='pselect' action='status.pl' method='POST'><input type='hidden' name='cgraphs' value='cgraphs'><button type='submit'>Clear</button></form></td></tr>";
  	} else {		
		if ($melapsed > 0) {  	  
		  $mcontrol .= "<td>Run time: " . $mrunt . "</td>";
		  $mcontrol .= "<td><form name='mstop' action='status.pl' method='POST'><input type='hidden' name='mstop' value='stop'><input type='submit' value='Stop' onclick='this.disabled=true;this.form.submit();' > ";
		} else { 
		  $mcontrol .= "<td class='error'>Stopped</td>";
		  $mcontrol .= "<td><form name='mstart' action='status.pl' method='POST'><input type='hidden' name='mstart' value='start'><input type='submit' value='Start' onclick='this.disabled=true;this.form.submit();' > ";
		}
		$mcontrol .= "<input type='password' placeholder='root password' name='ptext' required></td></form>";		
		my $mcheck = `ps -eo command | grep [m]gpumon | wc -l`;
		$mcontrol .=  "<td><A href=/mgpumon/>Farm Overview</A></td>" if ($mcheck >0);
	}
  }
} 
else {
 	if ($showminer == 0) {
 		$getmlinv = `cat /proc/version`;
 		$mlinv = $1 if ($getmlinv =~ /version\s(.*?\s+\(.*?\))\s+\(/);
     	$msput .= "<tr><td class='big'>Linux Version:</td><td>" . $mlinv . "</td></tr>";
		$avers = " (1." . $avers . ")" if ($avers ne "");
 		$msput .= "<tr><td>Miner Version (API)</td><td>" . $mvers . $avers . "</td></tr>";
 	}
}

$mcontrol .= "</tr></table><br>";

$p1sum .= "<table id='pcontent'>";

if ($ispriv eq "S") {
	$p1sum .= "<TR class='ghdr'><TD class='ghdr'>Pool</TD>";
	$p1sum .= "<TD class='ghdr'>Pool URL</TD>";
	if ($avers > 16) {
	  $p1sum .= "<TD class='ghdr'>Worker</TD>"; 
	}
	$p1sum .= "<TD class='ghdr'>Status</TD>";
	$p1sum .= "<TD class='ghdr' colspan=2>Accept/Reject</TD>";
	$p1sum .= "<TD class='ghdr'>Active</TD>";
	$p1sum .= "<TD class='ghdr'>Prio</TD>";
	#$p1sum .= "<TD class='ghdr' colspan=2>Quota (ratio or %)</TD>";
	$p1sum .= "</TR>";

	my @poolmsg; $pqb=0;
	if (@pools) { 
	  my $g0url = $gpus[0]{'pool_url'}; 
	  for (my $i=0;$i<@pools;$i++) {
	    $pimg = "<form name='pselect' action='status.pl' method='POST'><input type='hidden' name='swpool' value='$i'><button type='submit'>Switch</button></form>";
	    $pnum = ${@pools[$i]}{'poolid'};
	    $pname = ${@pools[$i]}{'url'};
	    $pimg = "<img src='/bamt/ok24.png'>" if ($g0url eq $pname);
	    $pusr = ${@pools[$i]}{'user'};
	    $pstat = ${@pools[$i]}{'status'};
	    if ($pstat eq "Dead") {
	      $problems++;
	      push(@nodemsg, "Pool $i is dead"); 
	      $pstatus = "<td class='error'>" . $pstat . "</td>";
		  if ($showpool == $i) {
		  	push(@poolmsg, "Pool is dead"); 
		  }	
	    } else {
	      $pstatus = "<td>" . $pstat . "</td>";
	    }
	    $pimg = "<img src='/bamt/error24.png'>" if ($pstat ne "Alive");
	    $ppri = ${@pools[$i]}{'priority'};
	    $pimg = "<img src='/bamt/timeout24.png'>" if (($g0url ne $pname)&&(($ppri eq 0)&&($pstat eq "Alive")));
	    $pacc = ${@pools[$i]}{'accepted'};
	    $prej = ${@pools[$i]}{'rejected'};
	    if ($prej ne "0") {
	      $prr = sprintf("%.2f", $prej / ($pacc + $prej)*100);
	    } else { 
		   $prr = "0.0";
	    }
		if (defined(${$conf}{settings}{monitor_reject_hi}) && ($prr > ${$conf}{settings}{monitor_reject_hi})) {
	      $problems++;
	      push(@nodemsg, "Pool $i reject ratio too high"); 
	  	  $prat = "<td class='error'>" . $prr . "%</td>";
		  if ($showpool == $i) {
	        push(@poolmsg, "Reject ratio is too high"); 
		  }	
	    } else { 
	      $prat = "<td>" . $prr . "%</td>";
	    }
	#    $pquo = ${@pools[$i]}{'quota'};
	#    $pqb++ if ($pquo ne "1");
	      if ($showpool == $i) { 
	      $psgw = ${@pools[$i]}{'getworks'};
	      $psw = ${@pools[$i]}{'works'}; 
	      $psd = ${@pools[$i]}{'discarded'}; 
	      $pss = ${@pools[$i]}{'stale'}; 
	      $psgf = ${@pools[$i]}{'getfails'}; 
	      $psrf = ${@pools[$i]}{'remotefailures'};
	      if ($g0url eq $pname) {
			$current = "Active";
	      } else { 
			$current = "Not Active  ";
	      }
	      $psput .= "<tr><form name='pdelete' action='status.pl' method='POST'><td class='big' colspan=4>$current";
	      if ($g0url ne $pname) {
	      $psput .= "<input type='hidden' name='delpool' value='$i'><input type='submit' value='Remove this pool'>";
	      }
	      $psput .= "</form></td></tr>";
	      $psput .= "<tr><td>Mining URL:</td><td colspan=3>" . $pname . "</td></tr>";
		  $puser = "unknown" if ($puser eq "");
	      $psput .= "<tr><td>Worker:</td><td colspan=3>" . $pusr . "</td></tr>";
	      $psput .= "<td>Status:</td>" . $pstatus;
	      $psput .= "<td>Shares A/R:</td><td>" . $pacc . " / " . $prej . "</td></tr>";


	      $psput .= "<tr><td>Priority:</td><td>" . $ppri . "</td>";
	      $psput .= "<td>Quota:</td><td>" . $ppri . "</td></tr>";
	      $psput .= "<tr><td>Getworks:</td><td>" . $psgw . "</td>";
	      $psput .= "<td>Works:</td><td>" . $psw . "</td></tr>";
	      $psput .= "<tr><td>Discarded:</td><td>" . $psd . "</td>";
	      $psput .= "<td>Stale:</td><td>" . $pss . "</td></tr>";
	      $psput .= "<tr><td>Get Failures:</td><td>" . $psgf . "</td>";
	      $psput .= "<td>Rem Fails:</td><td>" . $psrf . "</td></tr>";
	      $pgimg = "<br><img src='/IFMI/graphs/pool$i.png'>";

	    } else {
	      my $purl = "?";
	      $purl .= "pool=$i";
	      $psum .= '<TR><TD class="bigger"><A href="' . $purl . '">' . $i . '</TD>';
	      $psum .= "<td>" . $pname . "</td>";
	      if (length($pusr) > 20) { 
	        $pusr = substr($pusr, 1, 6) . " ... " . substr($pusr, -6, 6) if (index($pusr, '.') < 0);
	      }
	      if ($avers > 16) {
	        $psum .= "<td>" . $pusr . "</td>";
	      }
	      $psum .= $pstatus;
	      $psum .= "<td>" . $pacc . " / " . $prej . "</td>";
	      $psum .= $prat;
	      $psum .= "<td>" . $pimg . "</td>";
	      $psum .= "<td>" . $ppri . "</td>";
	#      $psum .= "<td>" . $pquo . "</td>";
	#      $psum .= "<td><form name='pquota' action='poolmanage.pl' method='text'>";
	#      $psum .= "<input type='text' size='3' name='qval' required>";
	#      $psum .= "<input type='hidden' name='qpool' value='$i'>";
	#      $psum .= "<input type='submit' value='Set'></form></td></tr>";
	    }
	  }
	  $psum .= "<tr><form name='padd' action='status.pl' method='POST'>";
	  $psum .= "<td colspan='2'><input type='text' size='45' placeholder='MiningURL:portnumber' name='npoolurl' required>";
	  $psum .= "</td><td colspan='2'><input type='text' placeholder='username.worker' name='npooluser' required>";
	  $psum .= "</td><td colspan='2'><input type='text' size='15' placeholder='worker password' name='npoolpw'>";
	  $psum .= "</td><td colspan='2'><input type='submit' value='Add'>"; 
	  $psum .= "</td></form></tr>";

	#if ($pqb ne "0") {
	#  $p1add .= "<td colspan='3'><form name='qreset' action='poolmanage.pl' method='text'>";
	#  $p1add .= "<input type='hidden' name='qreset' value='reset'>";
	#  $p1add .= "<input type='submit' value='Unset Quotas'></form></td>";
	#} else { 
	#  $p1add .= "<td colspan='3'><small>Failover Mode</small></td>"; 
	#}

	} else { 
	  $psum .= "<TR><TD colspan='8'><big>Active Pool Information Unavailable</big></td></tr>";
	}
	$psum .= "</table><br>";
	$p1sum .= $psum;

} else { 
  $p1sum .= "<TR><TD id=perror><p>The required API permissions do not appear to be available.<br>";
  $p1sum .= "If your miner is not in a stopped state,<br>";
  $p1sum .= "please ensure your cgminer.conf contains the following line:<br>";
  $p1sum .= '"api-allow" : "W:127.0.0.1",';
  $p1sum .= "</p></td></tr>";
  $p1sum .= "</table><br>";
}

# Overview starts here

print "<div id='overview'>";
print "<table><TR><TD>";
print "<table><TR><TD id='overviewlogo' rowspan=2><a href='https://github.com/starlilyth/bamt-poolmanager' target=_blank>";
print "<IMG src='/IFMI/IFMI-logo-small.png'></a></TD>";
print "<TD class='overviewid'>" . $conf{'settings'}{'miner_id'} . "</td>";
print "<td align='right'><form name='zero' action='status.pl' method='POST'><input type='hidden' name='zero' value='zero'>";
print "<input type='image' src='/IFMI/button_round_navy.png' width='10' height='10' alt='Zero Stats'></form></td>";
print "<tr><TD class='overviewhash' colspan=2>";
$minerate = "0" if ($minerate eq ""); 
print $minerate . " Mh/s</TD></tr></table></td>";
$mineacc = "0" if ($mineacc eq ""); 
print "<TD class='overview'>" . $mineacc . " total accepted shares<br>";
$minerej = "0" if ($minerej eq ""); 
print $minerej . " total rejected shares<br>";
if ($mineacc > 0)
{
 print sprintf("%.3f%%", $minerej / ($mineacc + $minerej)*100);
} else { 
 print "0"
}
print " reject ratio";

print "<TD class='overview'>";
if ($problemgpus > 1){
  if ($problemgpus == 1) {
  	print $problemgpus . " GPU has problems<br>";
  } else {
	print $problemgpus . " of " . @gpus . " GPUs have problems<br>";
  }
} else { 
  if ($okgpus == 1) {
	print $okgpus . " GPU is OK<br>";
  } else {
	print $okgpus . " of " . @gpus . " GPUs are OK<br>";
  }
}
$minehe = "0" if ($minehe eq ""); 
if ($minehe == 1) {
  print $minehe . " HW Error<br>";
} else {
  print $minehe . " HW Errors<br>";
}
$minewu = "0" if ($minewu eq ""); 
print $minewu . " Work Utility<br>";
print "</td>";

# EXTRA HEADER STATS
print "<TD class='overview'>";
my $uptime = `uptime`;
$rigup = $1 if ($uptime =~ /up\s+(.*?),\s+\d+\s+users,/);
$rigload = $1 if ($uptime =~ /average:\s+(.*?),/);
my $memfree = `cat /proc/meminfo | grep MemFree`; 
$rmem = $1 if ($memfree =~ /^MemFree:\s+(.*?)\s+kB$/);
$rigmem = sprintf("%.3f", $rmem / 1000000);  
print "Uptime: $rigup<br>";
print "CPU Load: $rigload<br>";
print "Mem free: $rigmem GB<br>";
# END EXTRA STATS

print "</TR></table></div>";

print "<div id=content>";

given($x) {
	when ($showgpu > -1) {
		print "<div id='showgpu'>";
		print "<A HREF=?";	
		print "tok=1> << Back to overview</A>";
		print "<P>";	
		print "<table><tr><td id='showgpustats'>";	
		print "<table><tr><td width=200px class='bigger'>GPU $showgpu<br>";	
		print sprintf("%d", $gpus[$showgpu]{'hashrate'}) . " Kh/s</td></tr>";	
		print "<tr><td>";
		if (@gpumsg) {
			print "<img src='/bamt/error.png'><p>";
			foreach my $l (@gpumsg) {
				print "$l<br>";
			}
		} else {
			print "<img src='/bamt/ok.png'><p>";
			print "All parameters OK";
		}
		print "</td></tr></table>";

		print "</td><td><div id='sumdata'><table class=datatbl>$gsput</table></div></td></tr></table></td>";	
		print "<tr><td>$ggimg</td></tr>";
		print "</div>";
	}
	when ($showpool > -1) {
        print "<div id='showgpu'>";
        print "<A HREF=?";
        print "tok=1> << Back to overview</A>";
        print "<P>";
        print "<table><tr><td id='showgpustats'>";
        print "<table><tr><td width=200px class='bigger'>Pool $showpool<br>";
        my $psacc = ${@pools[$showpool]}{'accepted'};
        my $psrej = ${@pools[$showpool]}{'rejected'};
		if ($psacc ne "0") { 
 	      print sprintf("%.2f%%", $psrej / ($psacc + $psrej)*100) . "</td></tr><tr><td>";
          print "reject ratio";
		} else {
		  print "0 Shares";
		}
		print "</td></tr><tr><td>";
        if (@poolmsg) {
                print "<p><img src='/bamt/error.png'><p>";
                foreach my $l (@poolmsg)
                {
                        print "$l<br>";
                }
        } else {
                print "<p><img src='/bamt/ok.png'><p>";
                print "All OK";
        }
   		print "</td></tr></table>";
		print "</td><td><div id='sumdata'><table class=datatbl>$psput</table></div></td></tr></table></td>";
		print "<tr><td>$pgimg</td></tr>";
		print "</div>";
	}
	when ($showminer > -1) {
        print "<div id='showgpu'>";
        print "<A HREF=?";
        print "tok=1> << Back to overview</A>";
        print "<P>";
        print "<table><tr><td id='showgpustats'>";
        print "<table><tr><td width=200px class='bigger'>" . $conf{'settings'}{'miner_id'} . "<br>";
		if (($minerate ne "0") && ($minewu ne "0")) {
 	      print sprintf("%.1f%%", ($minewu / $minerate) / 10);
		} else { print "0"; }
		print "</td></tr><tr><td>Efficiency (WU / Hashrate)</td></tr>"; 
		print "<tr><td>";
        if (@nodemsg) {
                print "<img src='/bamt/error.png'><p>";
                foreach my $l (@nodemsg)
                {
                        print "$l<br>";
                }
        } else {
                print "<p><img src='/bamt/ok.png'><p>";
                print "All OK";
        }
   		print "</td></tr></table>";        
        print "</td><td><table class=datatbl>$msput</td></tr>";
        print "<tr><td colspan=4><hr></td></tr>";
        print "<tr><td colspan=4>PoolManager was written by Lily, and updates are available at ";
        print "<a href=https://github.com/starlilyth/bamt-poolmanager target=_blank>GitHub</a>.<br>"; 
        print "If you love PoolManager, please consider donating. Thank you!<br> ";
        print "BTC: 1JBovQ1D3P4YdBntbmsu6F1CuZJGw9gnV6 <br>LTC: LdMJB36zEfTo7QLZyKDB55z9epgN78hhFb<br>";
        print "</table></td></tr></table>";
    	print "</div>";
	}
	default {
	  print "<div class='gpudata'>";

	  if ($UHOH eq "true") {
		print "<table><tr><td class=big><p>Uh Oh! No data could be retreived! Please check your configuration and try again.</p></td></tr></table>";
	  } else {
	    print $mcontrol;	
	    print $p1sum;
	    print $g1put;

		print "</div>";
		print "<div id=gpugraphs>";	
		print "<table id=graphs>";
		print "<tr><td>";	
		my $img = "/var/www/IFMI/graphs/msummary.png";
		if (-e $img) {
			print '<img src="/IFMI/graphs/msummary.png">';
		} else {
			print "<font style='color: #999999; font-size: 10px;'>Summary graph not available yet.";
		}
		print "</td></tr></table>";
		print "</div>";	
	  }
	}
}

print "</body></html>";

