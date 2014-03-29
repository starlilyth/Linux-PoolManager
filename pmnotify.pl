#!/usr/bin/perl
#    This file is part of IFMI PoolManager.
#
#    PoolManager is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
use strict;
use warnings;

use YAML qw( DumpFile LoadFile );
use Email::Simple::Creator;
use Email::Sender::Simple qw(sendmail);
use Email::Sender::Transport::SMTP;
use Email::Sender::Transport::SMTP::TLS;
use Try::Tiny;

require '/opt/ifmi/pm-common.pl';
my $conf = &getConfig;
my %conf = %{$conf};
my $conffile = "/opt/ifmi/poolmanager.conf";
my $miner_name = `hostname`;
chomp $miner_name;
my $nicget = `/sbin/ifconfig`; 
my $iptxt = "";
while ($nicget =~ m/(\w\w\w\w?\d)\s.+\n\s+inet addr:(\d+\.\d+\.\d+\.\d+)\s/g) {
  $iptxt = $2; 
}
my $now = POSIX::strftime("%m/%d at %H:%M", localtime());	

sub doEmail {
  my $emaildo = $conf{monitoring}{do_email};
  if ($emaildo == 1) {
		my $msg = "";
		my $ispriv = &CGMinerIsPriv; 
		if ($ispriv ne "S") {
			$msg .= "No miner data available - mining process may be stopped or hung!\n";
		} else {
			my $temphi = $conf{monitoring}{monitor_temp_hi};
			my $templo = $conf{monitoring}{monitor_temp_lo};
			my $hashlo = $conf{monitoring}{monitor_hash_lo};
			my $loadlo = $conf{monitoring}{monitor_load_lo};
			my $rejhi = $conf{monitoring}{monitor_reject_hi};
			my $fanlo = $conf{monitoring}{monitor_fan_lo};
			my $fanhi = $conf{monitoring}{monitor_fan_hi};
			my @gpus = &getFreshGPUData(1);
			for (my $i=0;$i<@gpus;$i++) {
				my $gpuid = "GPU$i";
				# stuff with settings
				if ($gpus[$i]{'current_temp_0_c'} > $conf{monitoring}{monitor_temp_hi}) {
					if (!(defined($conf{monitoring}{alert}{$gpuid}{temphi}))) {
						$msg .= "$gpuid temp is: $gpus[$i]{'current_temp_0_c'}C. ";
						$msg .= "Alert level is: $conf{monitoring}{monitor_temp_hi}C\n";
						$conf{monitoring}{alert}{$gpuid}{temphi} = 1;
					}
				} else {
					if (defined($conf{monitoring}{alert}{$gpuid}{temphi})) {
						$msg .= "$gpuid temp is: $gpus[$i]{'current_temp_0_c'}C. ";
						$msg .= "Alert has cleared.\n";
						delete $conf{monitoring}{alert}{$gpuid}{temphi}; 
					}
				}
				if ($gpus[$i]{'current_temp_0_c'} < $conf{monitoring}{monitor_temp_lo}) { 
					if (!(defined($conf{monitoring}{alert}{$gpuid}{templo}))) {
						$msg .= "$gpuid temp is: $gpus[$i]{'current_temp_0_c'}C. ";
						$msg .= "Alert level is: $conf{monitoring}{monitor_temp_lo}C\n";
						$conf{monitoring}{alert}{$gpuid}{templo} = 1; 
					}
				} else {
					if (defined($conf{monitoring}{alert}{$gpuid}{templo})) {
						$msg .= "$gpuid temp is: $gpus[$i]{'current_temp_0_c'}C. ";
						$msg .= "Alert has cleared.\n";
						delete $conf{monitoring}{alert}{$gpuid}{templo}; 
					}
				}
				my $frpm = $gpus[$i]{'fan_rpm_c'}; $frpm = "0" if ($frpm eq "");
				if (($frpm < $conf{monitoring}{monitor_fan_lo}) && ($frpm > 0)) {
					if (!(defined($conf{monitoring}{alert}{$gpuid}{fanlo}))) {
						$msg .= "$gpuid fan is: $gpus[$i]{'fan_rpm_c'}RPM. ";
						$msg .= "Alert level is: $conf{monitoring}{monitor_fan_lo} RPM\n";
						$conf{monitoring}{alert}{$gpuid}{fanlo} = 1;
					}
				} else {
					if (defined($conf{monitoring}{alert}{$gpuid}{fanlo})) {
						$msg .= "$gpuid fan is: $gpus[$i]{'fan_rpm_c'}RPM. ";
						$msg .= "Alert has cleared.\n";
						delete $conf{monitoring}{alert}{$gpuid}{fanlo};
					}
				}
				if (($frpm > $conf{monitoring}{monitor_fan_hi}) && ($frpm > 0)) {
					if (!(defined($conf{monitoring}{alert}{$gpuid}{fanhi}))) {
						$msg .= "$gpuid fan is: $gpus[$i]{'fan_rpm_c'}RPM. ";
						$msg .= "Alert level is: $conf{monitoring}{monitor_fan_hi}RPM\n";
						$conf{monitoring}{alert}{$gpuid}{fanhi} = 1;
					}
				} else {
					if (defined($conf{monitoring}{alert}{$gpuid}{fanhi})) {
						$msg .= "$gpuid fan is: $gpus[$i]{'fan_rpm_c'}RPM. ";
						$msg .= "Alert has cleared.\n";
						delete $conf{monitoring}{alert}{$gpuid}{fanhi};
					}
				}
				my $rr = "0";
				my $gsha = $gpus[$i]{'shares_accepted'};
				my $gshr = $gpus[$i]{'shares_invalid'}; $gshr = 0 if ($gshr eq "");
				if ($gshr > 0) {
			      $rr = sprintf("%.2f", $gshr / ($gsha + $gshr)*100);
				}
				if (($gsha > 0) && ($rr > ${$conf}{monitoring}{monitor_reject_hi})) {
					if (!(defined($conf{monitoring}{alert}{$gpuid}{rejhi}))) {
						$msg .= "$gpuid reject rate is: $rr%. ";
						$msg .= "Alert level is: $conf{monitoring}{monitor_reject_hi}%\n";
						$conf{monitoring}{alert}{$gpuid}{rejhi} = 1; 
					}
				} else {
					if (defined($conf{monitoring}{alert}{$gpuid}{rejhi})) {
						$msg .= "$gpuid reject rate is: $rr%. ";
						$msg .= "Alert has cleared.\n";
						delete $conf{monitoring}{alert}{$gpuid}{rejhi}; 
					}
				}

				if ($gpus[$i]{'current_load_c'} < $conf{monitoring}{monitor_load_lo}) { 
					if (!(defined($conf{monitoring}{alert}{$gpuid}{loadlo}))) {
						$msg .= "$gpuid load is: $gpus[$i]{'current_load_c'}. ";
						$msg .= "Alert level is: $conf{monitoring}{monitor_load_lo}\n";
						$conf{monitoring}{alert}{$gpuid}{loadlo} = 1;						
					}
				} else {
					if (defined($conf{monitoring}{alert}{$gpuid}{loadlo})) {
						$msg .= "$gpuid load is: $gpus[$i]{'current_load_c'}. ";
						$msg .= "Alert has cleared.\n";
						delete $conf{monitoring}{alert}{$gpuid}{loadlo}; 
					}
				}
				my $ghashrate = $gpus[$i]{'hashrate'}; 
				$ghashrate = $gpus[$i]{'hashavg'} if ($ghashrate eq "");
				if ($ghashrate < $conf{monitoring}{monitor_hash_lo}) { 
					if (!(defined($conf{monitoring}{alert}{$gpuid}{hashlo}))) {
						$msg .= "$gpuid hashrate is: $ghashrate Kh/s. ";
						$msg .= "Alert level is: $conf{monitoring}{monitor_hash_lo}Kh/s\n";
						$conf{monitoring}{alert}{$gpuid}{hashlo} = 1;
					}
				} else {
					if (defined($conf{monitoring}{alert}{$gpuid}{hashlo})) {
						$msg .= "$gpuid hashrate is: $ghashrate Kh/s. ";
						$msg .= "Alert has cleared.\n";
						delete $conf{monitoring}{alert}{$gpuid}{hashlo}; 
					}
				}
				# stuff without settings
				my $ghealth = $gpus[$i]{'status'}; 
		    	if ($ghealth ne "Alive") {
						if (!(defined($conf{monitoring}{alert}{$gpuid}{health}))) {		    		
		    			$msg .= "$gpuid health is: $ghealth.\n";
			    		$conf{monitoring}{alert}{$gpuid}{health} = 1; 
		    		}
		    	} else {
						if (defined($conf{monitoring}{alert}{$gpuid}{health})) {		    		
		    			$msg .= "$gpuid health is: $ghealth. ";
							$msg .= "Alert has cleared.\n";
							delete $conf{monitoring}{alert}{$gpuid}{health}; 
						}
		    	}
		    my $ghwe = $gpus[$i]{'hardware_errors'};	
				if ($ghwe > 0) { 
					if (!(defined($conf{monitoring}{alert}{$gpuid}{health}))) {		    		
						$msg .= "$gpuid has $ghwe Hardware Errors.\n";
						$conf{monitoring}{alert}{$gpuid}{health} = 1; 
					}
				} else {
					if (defined($conf{monitoring}{alert}{$gpuid}{health})) {		    		
						$msg .= "$gpuid has $ghwe Hardware Errors. ";
						$msg .= "Alert has cleared.\n";
						delete $conf{monitoring}{alert}{$gpuid}{health}; 
					}
				}
			}
			my @pools = &getCGMinerPools(1);
			if (@pools) { 
				for (my $i=0;$i<@pools;$i++) {
					my $phealth = ${$pools[$i]}{'status'}; 
	    		my $pname = ${$pools[$i]}{'url'};
	    		my $shorturl = "";
  				if ($pname =~ m|://(\w+-?\w+\.)?(\w+-?\w+\.\w+:\d+)|) {
     					$shorturl = $2;
  				}
					my $pactive = 0; 
					for (my $g=0;$g<@gpus;$g++) {
						if ($pname eq $gpus[$g]{'pool_url'}) {
							$pactive++;
						}
					}						
			   	my $poola; my $poolnum;
		      for (keys %{$conf{pools}}) {
		      	if ($pname eq ${$conf}{pools}{$_}{url}) {
		      		$poola = ${$conf}{pools}{$_}{alias};
		      		$poolnum = $_;
		      	}
		      }
		      my $poolid = "pool$poolnum";
					my $prr = "0"; 
				  my $pacc = ${$pools[$i]}{'accepted'}; 
				  my $prej = ${$pools[$i]}{'rejected'}; 
				  if (defined $prej && $prej > 0) {
				    $prr = sprintf("%.2f", $prej / ($pacc + $prej)*100);
			    }
			    my $prhl = ${$conf}{pools}{$poolnum}{pool_reject_hi}; 
					if ((defined $prej) && (defined $prhl) && ($prr > $prhl)) {
						if (!(defined($conf{monitoring}{alert}{$poolid}{rejhi}))) {
							$msg .= "Pool $i ($shorturl) reject rate is: $prr%. ";
							$msg .= "Alert level is: $prhl%\n";
							$conf{monitoring}{alert}{$poolid}{rejhi} = 1;
						}
					} else {
						if (defined($conf{monitoring}{alert}{$poolid}{rejhi})) {
							$msg .= "Pool $i ($shorturl) reject rate is: $prr%. ";
							$msg .= "Alert has cleared.\n";
							delete $conf{monitoring}{alert}{$poolid}{rejhi}; 
						}
					}
					my $pnotify = $conf{pools}{$poolnum}{pnotify};
					if (($phealth ne "Alive") && ($pnotify == 1)) {
						if (!(defined($conf{monitoring}{alert}{$poolid}{phealth}))) {						
							$msg .= "Pool $i ($shorturl) health is $phealth.";
							$conf{monitoring}{alert}{$poolid}{phealth} = 1; 
						}
					} else { 
						if (($phealth eq "Alive") && (defined($conf{monitoring}{alert}{$poolid}{phealth}))) {
							$msg .= "Pool $i ($shorturl) health is $phealth. ";
							$msg .= "Alert has cleared.\n";
							delete $conf{monitoring}{alert}{$poolid}{phealth};
						}
					}
				}
			}
			DumpFile($conffile, $conf); 
		}
		if ($msg ne "") { 
			my $email = "Alerts for $miner_name ($iptxt) - $now\n";		
			$email .= $msg; 
			my $subject = "Alerts for $miner_name ($iptxt) - $now";
			&sendAnEmail($subject, $email);
		}
	}
}

sub sendAnEmail {
	my ($subject,$message) = @_;
	my $to = $conf{email}{smtp_to};
	my $host = $conf{email}{smtp_host};
	my $from = $conf{email}{smtp_from};		
	my $port = $conf{email}{smtp_port};	
	my $tls = $conf{email}{smtp_tls};
	my $ssl = $conf{email}{smtp_ssl};
	if ($subject eq "TEST") {
		$subject = "Test Email from $miner_name ($iptxt) - $now";
	}
	if ($to ne "") {
		my $helo = $miner_name . 'nohost.net';
		#domain name picked entirely at random, and apparently perfect for the cause. 
		my $email = Email::Simple->create(
		  header => [
		   To      => $to,
		   From    => $from,
		   Subject => $subject,],	
		  body => $message,
		);	
		my $transport = "";
		if ($tls == 1) {
			$transport = Email::Sender::Transport::SMTP::TLS->new(
				host => $host,
				port => $port,
				helo => $helo,
				username => $conf{email}{smtp_auth_user},
				password => $conf{email}{smtp_auth_pass},
			);
		} elsif ($ssl == 1) {		
			$transport = Email::Sender::Transport::SMTP->new(
				host => $host,
				port => $port,
				helo => $helo,
				ssl => $ssl,
				sasl_username => $conf{email}{smtp_auth_user},
				sasl_password => $conf{email}{smtp_auth_pass},			
			);
		} else {
			$transport = Email::Sender::Transport::SMTP->new(
				host => $host,
				port => $port,
				helo => $helo,
			);
		}

		try { 
			sendmail($email, { transport => $transport });
		} finally {
			`/usr/bin/touch /tmp/pmnotify.lastsent`;
		} catch {
			return "Email Error: $_";
		};

	} else {
		die "No recipient!\n";
	}
}

1;