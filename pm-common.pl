#!/usr/bin/perl

#    This file is part of IFMI PoolManager.
#
#    PoolManager is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#

use YAML qw( LoadFile );
use IO::Socket::INET;
use Sys::Syslog qw( :DEFAULT setlogsock);
setlogsock('unix');
use JSON::XS;

sub saveConfig 
{
 my $savefile = $_[0];
 my $conf = &getConfig;
 %conf = %{$conf};
$savefile = "/opt/ifmi/cgminer.conf";
if (defined($conf{settings}{savepath})) {
  $savefile = $conf{settings}{savepath};
}
  if (-e $savefile) { 
   $bkpfile = $savefile . "-bkp";
   rename $savefile, $bkpfile; 
  }
   &blog("saving config to $savefile...");
   
         my $cgport = 4028;
         if (defined(${$conf}{'settings'}{'cgminer_port'}))
         {
                 $cgport = ${$conf}{'settings'}{'cgminer_port'};
         }
         my $sock = new IO::Socket::INET (
                PeerAddr => '127.0.0.1',
                PeerPort => $cgport,
                Proto => 'tcp',
                ReuseAddr => 1,
                Timeout => 10,
               );
        if ($sock)
        {
        &blog("sending save command to cgminer api");
	print $sock "save|$savefile";
                my $res = "";
                while(<$sock>)
                {
                        $res .= $_;
                }
                close($sock);
	        &blog("success!");
        }
        else
        {
                &blog("failed to get socket for cgminer api");
        }   
}

sub switchPool 
{
 my $conf = &getConfig;
 %conf = %{$conf};
 my $preq = $_[0];
   &blog("switching to pool $preq ...");
         my $cgport = 4028;
         if (defined(${$conf}{'settings'}{'cgminer_port'}))
         {
                 $cgport = ${$conf}{'settings'}{'cgminer_port'};
         }
         my $sock = new IO::Socket::INET (
                PeerAddr => '127.0.0.1',
                PeerPort => $cgport,
                Proto => 'tcp',
                ReuseAddr => 1,
                Timeout => 10,
               );
        if ($sock)
        {
        &blog("sending switchpool command to cgminer api");
        print $sock "switchpool|$preq\n"; 
                my $res = "";
                while(<$sock>)
                {
                        $res .= $_;
                }
                close($sock);
	        &blog("success!");
        }
        else
        {
                &blog("failed to get socket for cgminer api");
        }
}

sub quotaPool 
{
 my $conf = &getConfig;
 %conf = %{$conf};
 my $preq = $_[0];
 my $pqta = $_[1];
   &blog("setting quota on pool $preq to $pqta ...");

         my $cgport = 4028;
         if (defined(${$conf}{'settings'}{'cgminer_port'}))
         {
                 $cgport = ${$conf}{'settings'}{'cgminer_port'};
         }
         my $sock = new IO::Socket::INET (
                PeerAddr => '127.0.0.1',
                PeerPort => $cgport,
                Proto => 'tcp',
                ReuseAddr => 1,
                Timeout => 10,
               );
        if ($sock)
        {
        &blog("sending poolquota command to cgminer api");
        print $sock "poolquota|$preq,$pqta"; 
                my $res = "";
                while(<$sock>)
                {
                        $res .= $_;
                }
                close($sock);
	        &blog("success!");
        }
        else
        {
                &blog("failed to get socket for cgminer api");
        }
}

sub addPool 
{
 my $conf = &getConfig;
 %conf = %{$conf};
 my $purl = $_[0];
 my $puser = $_[1];
 my $ppw = $_[2];
 $ppw = " " if ($ppw eq "");   
   &blog("adding new pool ...");

         my $cgport = 4028;
         if (defined(${$conf}{'settings'}{'cgminer_port'}))
         {
                 $cgport = ${$conf}{'settings'}{'cgminer_port'};
         }
         my $sock = new IO::Socket::INET (
                PeerAddr => '127.0.0.1',
                PeerPort => $cgport,
                Proto => 'tcp',
                ReuseAddr => 1,
                Timeout => 10,
               );
        if ($sock)
        {
        &blog("sending addpool command to cgminer api");
        print $sock "addpool|$purl,$puser,$ppw"; 
                my $res = "";
                while(<$sock>)
                {
                        $res .= $_;
                }
                close($sock);
	        &blog("success!");
        }
        else
        {
                &blog("failed to get socket for cgminer api");
        }
}

sub delPool 
{
 my $conf = &getConfig;
 %conf = %{$conf};
 my $delreq = $_[0];
   &blog("deleting pool $delreq ...");
         my $cgport = 4028;
         if (defined(${$conf}{'settings'}{'cgminer_port'}))
         {
                 $cgport = ${$conf}{'settings'}{'cgminer_port'};
         }
         my $sock = new IO::Socket::INET (
                PeerAddr => '127.0.0.1',
                PeerPort => $cgport,
                Proto => 'tcp',
                ReuseAddr => 1,
                Timeout => 10,
               );
        if ($sock)
        {
        &blog("sending removepool command to cgminer api");
        print $sock "removepool|$delreq\n"; 
                my $res = "";
                while(<$sock>)
                {
                        $res .= $_;
                }
                close($sock);
	        &blog("success!");
        }
        else
        {
                &blog("failed to get socket for cgminer api");
        }
}

sub zeroStats 
{
 my $conf = &getConfig;
 %conf = %{$conf};
 my $delreq = $_[0];
   &blog("zeroing stats!");
         my $cgport = 4028;
         if (defined(${$conf}{'settings'}{'cgminer_port'}))
         {
                 $cgport = ${$conf}{'settings'}{'cgminer_port'};
         }
         my $sock = new IO::Socket::INET (
                PeerAddr => '127.0.0.1',
                PeerPort => $cgport,
                Proto => 'tcp',
                ReuseAddr => 1,
                Timeout => 10,
               );
        if ($sock)
        {
        &blog("sending zero command to cgminer api");
        print $sock "zero|all,false\n"; 
                my $res = "";
                while(<$sock>)
                {
                        $res .= $_;
                }
                close($sock);
          &blog("success!");
        }
        else
        {
                &blog("failed to get socket for cgminer api");
        }
}

sub getConfig
{

 my $conffile = '/opt/ifmi/poolmanager.conf';
 if (! -e $conffile) {
  exec('/usr/lib/cgi-bin/config.pl');
 }

 my $c;
 $c = LoadFile($conffile);
 return($c);
}


sub getGPUConfig
{
 my ($gpu) = @_;
 
 my $conf = &getConfig;
 %conf = %{$conf}; 

 return($conf{'gpu'.$gpu});

}

sub getGPUData
{
	my ($su) = @_;
	
	return(&getFreshGPUData($su));
}

sub getFreshGPUData
{
	my ($su) = @_;

	my @gpus;

#	my $uptime = `uptime`;
#	chomp($uptime);
	
	my $conf = &getConfig;
    %conf = %{$conf}; 
	
	my @cgpools = getCGMinerPools();	

  my $gpucount = &getCGMinerGPUCount;

  my $gidata = "";
  for (my $i=0;$i<$gpucount;$i++)
  {
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

	  	# mining data
		
		my $gc = &getGPUConfig($gpu);
		
		if (! ${$gc}{'disabled'})
		{
			${$gpus[$gpu]}{miner} = 'cgminer';
			&getCGMinerStats($gpu, \%{$gpus[$gpu]}, @cgpools );				
		}
		else
		{
			${$gpus[$gpu]}{pool_url} = 'GPU is disabled in config';
			${$gpus[$gpu]}{status} = 'disabled';
		}
		
		# monitoring
	
		# if (!defined(${$gc}{'disabled'}) || (${$gc}{'disabled'} == 0))
		# {		
                
		# 	if (defined(${$gc}{'monitor_fan_lo'}))
		# 	{
		# 		if (isdigit($gpus[$gpu]{fan_rpm_c}))
		# 		{
		# 			if ($gpus[$gpu]{fan_rpm_c} <  ${$gc}{'monitor_fan_lo'})
		# 			{
		# 				$gpus[$gpu]{fault_fan_lo} = ${$gc}{'monitor_fan_lo'} . '|' . $gpus[$gpu]{fan_rpm_c};
		# 			}
		# 		}
		# 	}               
			
		# 	if (defined(${$gc}{'monitor_load_lo'}))
		# 	{
		# 		if ($gpus[$gpu]{current_load_c} <  ${$gc}{'monitor_load_lo'})
		# 		{
		# 			$gpus[$gpu]{fault_load_lo} = ${$gc}{'monitor_load_lo'} . '|' . $gpus[$gpu]{current_load_c};
		# 		}
		# 	}
		
		# 	if (defined(${$gc}{'monitor_hash_lo'}) && defined($gpus[$gpu]{hashrate}))
		# 	{
		# 		if ($gpus[$gpu]{hashrate} < ${$gc}{'monitor_hash_lo'})
		# 		{
		# 			$gpus[$gpu]{fault_hash_lo} = ${$gc}{'monitor_hash_lo'} . '|' . $gpus[$gpu]{hashrate};
		# 		}
		# 	}
			
		# 	if (defined(${$gc}{'monitor_reject_hi'}))
		# 	{
		# 		if ($gpus[$gpu]{'shares_accepted'})
		# 		{
		# 			my $rr = $gpus[$gpu]{'shares_invalid'}/($gpus[$gpu]{'shares_accepted'} + $gpus[$gpu]{'shares_invalid'}) * 100;		
			
		# 			if ($rr > ${$gc}{'monitor_reject_hi'})
		# 			{
		# 				$gpus[$gpu]{fault_reject_hi} = ${$gc}{'monitor_reject_hi'} . '|' . $rr;
		# 			}
		# 		}
		# 	}
		
		# 	if (defined(${$gc}{'monitor_temp_lo'}))
		# 	{
		# 		if ($gpus[$gpu]{current_temp_0_c} < ${$gc}{'monitor_temp_lo'})
		# 		{
		# 			$gpus[$gpu]{fault_temp_lo} = ${$gc}{'monitor_temp_lo'} . '|' . $gpus[$gpu]{current_temp_0_c};
		# 		}
		# 	}
		
		# 	if (defined(${$gc}{'monitor_temp_hi'}))
		# 	{
		# 		if ($gpus[$gpu]{current_temp_0_c} > ${$gc}{'monitor_temp_hi'})
		# 		{
		# 			$gpus[$gpu]{fault_temp_hi} = ${$gc}{'monitor_temp_hi'} . '|' . $gpus[$gpu]{current_temp_0_c};
		# 		}
			
		# 	}
		
  #   }           
        
  }      	
  return(@gpus);
}

sub getCGMinerPools
{	 
	my @pools;
	
	my $conf = &getConfig;
    	%conf = %{$conf}; 

  my $cgport = 4028;
 	if (defined(${$conf}{'settings'}{'cgminer_port'}))
 	{
 	  $cgport = ${$conf}{'settings'}{'cgminer_port'};
 	}
    
	my $sock = new IO::Socket::INET (
          PeerAddr => '127.0.0.1',
          PeerPort => $cgport,
          Proto => 'tcp',
          ReuseAddr => 1,
          Timeout => 10,
         );

    if ($sock)
    {
    	print $sock "pools|\n";
    
		my $res = "";
		
		while(<$sock>) 
		{
			$res .= $_;
		}
		
		close($sock);

	      my $poid = ""; $pdata = ""; 
    	  while ($res =~ m/POOL=(\d+),(.+?)\|/g) {
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
}

sub getCGMinerStats
{
	my ($gpu, $data, @pools) = @_;
    
    my $conf = &getConfig;
    %conf = %{$conf}; 
    
    my $cgport = 4028;
 	if (defined(${$conf}{'settings'}{'cgminer_port'}))
 	{
 	  $cgport = ${$conf}{'settings'}{'cgminer_port'};
 	}
    
	my $sock = new IO::Socket::INET (
        PeerAddr => '127.0.0.1',
        PeerPort => $cgport,
        Proto => 'tcp',
        ReuseAddr => 1,
        Timeout => 10,
       );  
  if ($sock)
  {
    	print $sock "gpu|$gpu\n";
    
		my $res = "";
		
		while(<$sock>) 
		{
			$res .= $_;
		}
		
		close($sock);
	
		if ($res =~ m/MHS\s\ds=(\d+\.\d+),/) {
			$data->{'hashrate'} = $1 * 1000;
		}
    if ($res =~ m/MHS\sav=(\d+\.\d+),/) {
      $data->{'hashavg'} = $1 * 1000;
    }
		if ($res =~ m/Accepted=(\d+),/)	{
			$data->{'shares_accepted'} = $1;
		}		
		if ($res =~ m/Rejected=(\d+),/) {
			$data->{'shares_invalid'} = $1;
		}		
		if ($res =~ m/Status=(\w+),/)	{
			$data->{'status'} = $1;
		}
    if ($res =~ m/Enabled=(\w+),/) {
      $data->{'enabled'} = $1;
    }
    if ($res =~ m/Device\sElapsed=(.+?),/) {
      $data->{'elapsed'} = $1; #I get no data here.
    }
		if ($res =~ m/Hardware\sErrors=(\d+),/)	{
			$data->{'hardware_errors'} =$1;
		}
		if ($res =~ m/Intensity=(\d+),/) {
			$data->{'intensity'} =$1;
		}		
		if ($res =~ m/Last\sShare\sPool=(\d+),/) {
			foreach $p (@pools)	{
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
	} else {
		$url = "cgminer socket failed";
	}
}

sub getCGMinerGPUCount
{
    my $conf = &getConfig;
    %conf = %{$conf};
    my $cgport = 4028;
        if (defined(${$conf}{'settings'}{'cgminer_port'})) {
          $cgport = ${$conf}{'settings'}{'cgminer_port'};
        }
        my $sock = new IO::Socket::INET (
            PeerAddr => '127.0.0.1',
            PeerPort => $cgport,
            Proto => 'tcp',
            ReuseAddr => 1,
            Timeout => 10,
           );
    if ($sock) {
      print $sock "gpucount|\n";
      my $res = "";
      while(<$sock>) {
        $res .= $_;
      }
      close($sock);
      while ($res =~ m/Count=(\d+)/g) {
        return $1; 
      }
    } else {
      $url = "cgminer socket failed";
    }
}

sub getCGMinerVersion
{
    my $conf = &getConfig;
    %conf = %{$conf};
    my $cgport = 4028;
        if (defined(${$conf}{'settings'}{'cgminer_port'})) {
          $cgport = ${$conf}{'settings'}{'cgminer_port'};
        }
        my $sock = new IO::Socket::INET (
            PeerAddr => '127.0.0.1',
            PeerPort => $cgport,
            Proto => 'tcp',
            ReuseAddr => 1,
            Timeout => 10,
           );
    if ($sock) {
      print $sock "version|\n";
      my $res = "";
      while(<$sock>) {
        $res .= $_;
      }
      close($sock);
      while ($res =~ m/VERSION,(\w+?=\d+\.\d+\.\d+,API=\d+\.\d+)/g) {
        return $1; 
      }
    } else {
      $url = "cgminer socket failed";
    }
}

sub CGMinerIsPriv
{
    my $conf = &getConfig;
    %conf = %{$conf};
    my $cgport = 4028;
        if (defined(${$conf}{'settings'}{'cgminer_port'})) {
          $cgport = ${$conf}{'settings'}{'cgminer_port'};
        }
    my $sock = new IO::Socket::INET (
              PeerAddr => '127.0.0.1',
              PeerPort => $cgport,
              Proto => 'tcp',
              ReuseAddr => 1,
              Timeout => 10,
             );
    if ($sock)
    {
        print $sock "privileged|\n";
        my $res = "";
        while(<$sock>) {
          $res .= $_;
        }
        close($sock);
        while ($res =~ m/STATUS=(\w),/g) {
        return $1;
        }
    } else {
        $url = "cgminer socket failed";
    }
}

sub getCGMinerSummary
{    
    my $conf = &getConfig;
    %conf = %{$conf}; 

  my @summary; 
 
    my $cgport = 4028;
 	if (defined(${$conf}{'settings'}{'cgminer_port'}))
 	{
 	  $cgport = ${$conf}{'settings'}{'cgminer_port'};
 	}
    
	my $sock = new IO::Socket::INET (
          PeerAddr => '127.0.0.1',
          PeerPort => $cgport,
          Proto => 'tcp',
          ReuseAddr => 1,
          Timeout => 10,
         );
    
    if ($sock)
    {
    	print $sock "summary|\n";
    
		my $res = "";
		
		while(<$sock>) 
		{
			$res .= $_;
		}
		
		close($sock);

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
    } else {
    	$url = "cgminer socket failed";
    }
	
}

sub stopCGMiner
{
 		
 my $conf = &getConfig;
 %conf = %{$conf};  
 
 &blog("stopping mining processes...");
 	  my $cgport = 4028;
 	  if (defined(${$conf}{'settings'}{'cgminer_port'}))
 	  {
 	  	 $cgport = ${$conf}{'settings'}{'cgminer_port'};
 	  }
 	  my $sock = new IO::Socket::INET (
          PeerAddr => '127.0.0.1',
          PeerPort => $cgport,
          Proto => 'tcp',
          ReuseAddr => 1,
          Timeout => 10,
         );
    
    if ($sock)
    {
    	&blog("send quit command to cgminer api");
  	 
    	print $sock "quit|\n";
    
  		my $res = "";
  		
  		while(<$sock>) 
  		{
  			$res .= $_;
  		}
  		
  		close($sock);
  	} else {
  		&blog("failed to get socket for cgminer api");
  	}	
}


sub startCGMiner
{

 my $conf = &getConfig;
 %conf = %{$conf};  

  my $minerbin = ${$conf}{'settings'}{'cgminer_path'}; 
  if ($minerbin eq "") {
    die "No miner path defined! Exiting."; 
  }
  my $mineropts =  ${$conf}{'settings'}{'cgminer_opts'}; 	
	my $pid = fork(); 
	
    if (not defined $pid)
    {
      die "out of resources? forking failed for cgminer process";
    }
    elsif ($pid == 0)
    {
    	$ENV{DISPLAY} = ":0";
    	$ENV{LD_LIBRARY_PATH} = "/opt/AMD-APP-SDK-v2.4-lnx32/lib/x86/:/opt/AMDAPP/lib/x86_64:";
      $ENV{GPU_USE_SYNC_OBJECTS} = "1";
    	
    	my $cmd = "/usr/bin/screen -d -m -S PM-miner $minerbin $mineropts"; 
    	
    	&blog("starting miner with cmd: $cmd");
    	
		exec($cmd);
		exit(0);
	}
	
}


sub doFAN
{
 my ($gpu) = @_;

 my $gc = &getGPUConfig($gpu);

 
 if (! ${$gc}{'disabled'})
 {
 	  
   # set fan
   if (defined(${$gc}{'fan_speed'}))
   {
   	    print "..fan $gpu";	  

   	    my $cmd = 'DISPLAY=:0.0 /usr/local/bin/atitweak -A ' . $gpu;

   	    $cmd .= ' -f ' . ${$gc}{'fan_speed'};
   	    
   	    &blog("fan cmd for gpu $gpu: " . $cmd);
   	    
   	    my $res = `$cmd`;
   }
 }
}



sub getTimestamp
{
 @months = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
 @weekDays = qw(Sun Mon Tue Wed Thu Fri Sat Sun);
 ($second, $minute, $hour, $dayOfMonth, $month, $yearOffset, $dayOfWeek, $dayOfYear, $daylightSavings) = gmtime();
 $year = 1900 + $yearOffset;
 return("$hour:$minute:$second, $weekDays[$dayOfWeek] $months[$month] $dayOfMonth, $year");
 
}

sub blog
{
	my ($msg) = @_;

	my @parts = split(/\//, $0);
	my $task = $parts[@parts-1];
	
    openlog($task,'nofatal,pid','local5');
    syslog('info', $msg);
    closelog;
}


sub getPCIGPUdata
{
	my @pci = `lspci -mm`;
	
	my @gpus;
	
	foreach $l (@pci)
	{
		if ($l =~ /(..\:..\..)\s\"VGA\scompatible\scontroller\"\s\"(.+?)\"\s\"(.+?)\"\s\"(.+?)\"\s\"(.+?)\"/)
		{
			push (@gpus, ({ pciid => $1, vendor => $2, device=> $3, svendor => $4, sdevice => $5, }) );
		}
	}

	return(@gpus);	

}


1;
