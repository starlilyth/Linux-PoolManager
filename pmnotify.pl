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

use Email::Simple::Creator;
use Email::Sender::Simple qw(try_to_sendmail);
use Email::Sender::Transport::SMTP;
use Email::Sender::Transport::SMTP::TLS;
use Try::Tiny;

require '/opt/ifmi/pm-common.pl';
my $conf = &getConfig;
my %conf = %{$conf};

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
				# stuff with settings
				if ($gpus[$i]{'current_temp_0_c'} > $conf{monitoring}{monitor_temp_hi}) {
					$msg .= "GPU$i temp is: $gpus[$i]{'current_temp_0_c'} C. ";
					$msg .= "Alert level is: $conf{monitoring}{monitor_temp_hi}\n";
				}
				if ($gpus[$i]{'current_temp_0_c'} < $conf{monitoring}{monitor_temp_lo}) { 
					$msg .= "GPU$i temp is: $gpus[$i]{'current_temp_0_c'} C. ";
					$msg .= "Alert level is: $conf{monitoring}{monitor_temp_lo}\n";
				}
				my $frpm = $gpus[$i]{'fan_rpm_c'}; $frpm = "0" if ($frpm eq "");
				if (($frpm < $conf{monitoring}{monitor_fan_lo}) && ($frpm > 0)) {
					$msg .= "GPU$i fan is: $gpus[$i]{'fan_rpm_c'} RPM. ";
					$msg .= "Alert level is: $conf{monitoring}{monitor_fan_lo}\n";
				}
				if ($frpm > $conf{monitoring}{monitor_fan_hi}) {
					$msg .= "GPU$i fan is: $gpus[$i]{'fan_rpm_c'} RPM. ";
					$msg .= "Alert level is: $conf{monitoring}{monitor_fan_hi}\n";
				}
				my $rr = "0";
				my $gsha = $gpus[$i]{'shares_accepted'}; $gsha = 0 if ($gsha eq "");
				if ($gsha > 0) {
					$rr = $gpus[$i]{'shares_invalid'}/($gpus[$i]{'shares_accepted'} + $gpus[$i]{'shares_invalid'})*100 ;		
				}
				if ($rr > ${$conf}{monitoring}{monitor_reject_hi}) {
					$msg .= "GPU$i reject rate is: $rr %. ";
					$msg .= "Alert level is: $conf{monitoring}{monitor_reject_hi}\n";
				}
				if ($gpus[$i]{'current_load_c'} < $conf{monitoring}{monitor_load_lo}) { 
					$msg .= "GPU$i load is: $gpus[$i]{'current_load_c'}. ";
					$msg .= "Alert level is: $conf{monitoring}{monitor_load_lo}\n";
				}
				my $ghashrate = $gpus[$i]{'hashrate'}; 
				$ghashrate = $gpus[$i]{'hashavg'} if ($ghashrate eq "");
				if ($ghashrate < $conf{monitoring}{monitor_hash_lo}) { 
					$msg .= "GPU$i hashrate is: $ghashrate. ";
					$msg .= "Alert level is: $conf{monitoring}{monitor_hash_lo}\n";
				}
				# stuff without settings
				my $ghealth = $gpus[$i]{'status'}; 
		    	if ($ghealth ne "Alive") {
		    		$msg .= "GPU$i health is: $ghealth.\n";
		    	}
		    	my $ghwe = $gpus[$i]{'hardware_errors'};	
				if ($ghwe > 0) { 
					$msg .= "GPU$i has $ghwe Hardware Errors.\n";
				}
			}
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
			if ( try_to_sendmail($email, { transport => $transport }) ) {
				`/usr/bin/touch /tmp/pmnotify.lastsent`;
			}
		} catch {
			print "error sending alert email: $!\n";
		};

	} else {
		die "No recipient!\n";
	}
}

1;