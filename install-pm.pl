#!/usr/bin/perl
# IFMI PoolManager installer. 
#    This file is part of IFMI PoolManager.
#
#    PoolManager is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.   
use strict;
use warnings;
use File::Path qw(make_path);
use File::Copy; 

my $login = (getpwuid $>);
die "Please run as root (do not use sudo)" if ($login ne 'root');
die "please execute from the install directory.\n" if (!-f "./pminstall.pl") ;

print "This will install the IFMI PoolManager for cgminer and clones on Linux.\n";
print "Are you sure? (y/n) ";
my $ireply = <>; chomp $ireply;
if ($ireply =~ m/y(es)?/i) {
	if (-d "/var/www/IFMI/") {
		print "It looks like this has been installed before. Do over? (y/n) ";
		my $oreply = <>; chomp $oreply; 
		if ($oreply =~ m/y(es)?/i) {
			&doInstall; 
		} else {
			die "Installation exited!\n";
		}
	} else {
		&doInstall; 
	}
} else {
	die "Installation exited!\n";
}

sub doInstall {
	use POSIX qw(strftime);
	my $now = POSIX::strftime("%Y-%m-%d.%H:%M", localtime());	
	my $instlog = "PoolManager Install Log.\n$now\n";
	print "Perl module check \n";
	require RRDs;
	require YAML;
	require JSON;
	print " ..all set!\n";
	$instlog .= "Perl test passed.";

# The following three values may need adjusting on systems that are not Debian or RedHat based. 
	my $webdir = "/var/www";
	my $cgidir = "/usr/lib/cgi-bin";
  	my $apacheuser = "unknown";

	my $appdir = "/opt/ifmi";
  	$apacheuser = "apache" if (-f "/etc/redhat-release");
  	$apacheuser = "www-data" if (-f "/etc/debian_version"); 
  	if ($apacheuser ne "unknown") {
	    if (-d $webdir && -d $cgidir) { 
			print "Copying files...\n";
			# perl chown requires UID and make_path is broken, so
			make_path $appdir . '/rrdtool';
			`chown $apacheuser $appdir`;
			make_path $webdir . '/IFMI/graphs' ;
			mkdir $webdir . '/IFMI/themes';
	      	if (!-f $webdir . "/index.html.pre-ifmi") {
	        	copy $webdir . "/index.html", $webdir . "/index.html.pre-ifmi" if (-f $webdir . "/index.html");
	      	}
	      	copy "index.html", $webdir;
	      	if (!-f $cgidir . "/status.pl.pre-ifmi") {
	      		copy $cgidir . "/status.pl", $cgidir . "/status.pl.pre-ifmi" if (-f $cgidir . "/status.pl"); 			
	      	}
	      	copy "status.pl", $cgidir;
			copy "config.pl", $cgidir;
	      	copy "confedit.pl", $cgidir;
	        copy "farmview", $appdir;
	      	copy "favicon.ico", $webdir;
	      	copy "mcontrol", $appdir;
	      	copy "pm-common.pl", $appdir;
		  	copy "pmgraph.pl", $appdir . "/rrdtool"; 
	        copy "run-poolmanager.pl", $appdir;
		    copy "sendstatus.pl", $appdir;
	      	`cp themes/* $webdir/IFMI/themes`;
	      	`cp images/*.png $webdir/IFMI`;
	      	`chmod 0755 $cgidir/*.pl`; #because windows
			`chown $apacheuser $appdir/poolmanager.conf` if (-f "$appdir/poolmanager.conf");
	      	$instlog .= "files copied.\n";
		} else { 
			die "Your web directories are in unexpected places. Quitting.\n";
		}
		copy "/etc/crontab", "/etc/crontab.pre-ifmi" if (!-f "/etc/crontab.pre-ifmi");
	    if (! `grep -E  ^"\* \* \* \* \* root /opt/ifmi/run-poolmanager.pl" /etc/crontab`) {
			print "Setting up crontab...\n";
	        open my $cin, '>>', "/etc/crontab";
	    	print $cin "* * * * * root /opt/ifmi/run-poolmanager.pl\n\n";
	    	close $cin;
		    $instlog .= "crontab modified.\n";
	    }
		copy "/etc/sudoers", "/etc/sudoers.pre-ifmi" if (!-f "/etc/sudoers.pre-ifmi");
		if (! `grep -E /opt/ifmi/mcontrol /etc/sudoers`) {
		    print "Modifying sudoers....\n";
	      	open my $sin, '>>', "/etc/sudoers";
	 		print $sin "Defaults targetpw\n$apacheuser ALL=(ALL) /opt/ifmi/mcontrol,/bin/cp,/usr/bin/reboot\n";
			close $sin;
			$instlog .= "sudoers modified.\n";
		}
		print "PoolManager attempts to set up some basic security for your web service.\n";
		print "It will enable SSL and redirect all web traffic over https.\n";
		print "It will also optionally set up a default site password.\n";
		if (!-f "/etc/ssl/certs/apache.crt") {
			print "First, we need to create a self-signed cert to enable SSL.\n";
			print "The next set of questions is information for this cert.\n";
			print "Please set the country code, and the rest of the cert quetions can be left blank.\n";
			print "Press any key to continue: ";
			my $creply = <>; 
			if ($creply =~ m/.*/) {
			    `/usr/bin/openssl req -x509 -nodes -days 1825 -newkey rsa:2048 -keyout /etc/ssl/private/apache.key -out /etc/ssl/certs/apache.crt`;
			    print "...finished creating cert.\n";
			    $instlog .= "cert created.\n";
			}
	 	} else {
    		print "...cert appears to be installed, skipping...\n";
		}
		my $restart = 0; 
	   	copy "/etc/apache2/sites-available/default-ssl", "/etc/apache2/sites-available/default-ssl.pre-ifmi"
			if (!-f "/etc/apache2/sites-available/default-ssl.pre-ifmi");
 	    if (`grep ssl-cert-snakeoil.pem /etc/apache2/sites-available/default-ssl`) {
	  		`sed -i "s/ssl-cert-snakeoil.pem/apache.crt/g" /etc/apache2/sites-available/default-ssl`;
  			`sed -i "s/ssl-cert-snakeoil.key/apache.key/g" /etc/apache2/sites-available/default-ssl`;
	  		$instlog .= "cert installed.\n";
  			`/usr/sbin/a2ensite default-ssl`;
	  		`/usr/sbin/a2enmod ssl`;
	  		$restart++;
  		}
		if (! `grep ServerName /etc/apache2/sites-available/default-ssl`) {
			open my $din, '<', "/etc/apache2/sites-available/default-ssl";
	 	    open my $dout, '>', "/etc/apache2/sites-available/default-ssl.out";
	 	    while (<$din>) {
 		    	print $dout $_;
 	    		last if /ServerAdmin /;
 	   		}
	 	    print $dout "\n	ServerName IFMI:443\n";
	 	    while (<$din>) {
 		    	print $dout $_;
 		    }
 	    	close $dout;
  			move "/etc/apache2/sites-available/default-ssl.out", "/etc/apache2/sites-available/default-ssl";
 	    } 
 	    if (! `grep RewriteEngine /etc/apache2/sites-available/default`) {
	 	    copy "/etc/apache2/sites-available/default", "/etc/apache2/sites-available/default.pre-ifmi"
	 	    	if (!-f "/etc/apache2/sites-available/default.pre-ifmi");
	 	    open my $din, '<', "/etc/apache2/sites-available/default";
	 	    open my $dout, '>', "/etc/apache2/sites-available/default.out";
	 	    while (<$din>) {
 		    	print $dout $_;
 	    		last if /ServerAdmin /;
 	   		}
	 	    print $dout "\n	RewriteEngine On\n	RewriteCond %{HTTPS} !=on\n";
	 	    print $dout "	RewriteRule ^/?(.*) https://%{SERVER_NAME}/\$1 [R,L]\n";
	 	    while (<$din>) {
 		    	print $dout $_;
 		    }
 	    	close $dout;
			move "/etc/apache2/sites-available/default.out", "/etc/apache2/sites-available/default";
	  		$instlog .= "rewrite enabled.\n";
		  	`/usr/sbin/a2enmod rewrite`;
		  	$restart++;
	  	}
 		print "Would you like to password protect the default site?(y/n) ";
		my $hreply = <>; chomp $hreply;
		if ($hreply =~ m/y(es)?/i) {
			if (! `grep AuthUserFile /etc/apache2/sites-available/default-ssl`) {
			    print "Configuring Apache for basic authentication...\n";
		    	copy "/etc/apache2/sites-available/default-ssl", "/etc/apache2/sites-available/default-ssl.pre-ifmi"
					if (!-f "/etc/apache2/sites-available/default-ssl.pre-ifmi");
				open my $din, '<', "/etc/apache2/sites-available/default-ssl";
		 	    open my $dout, '>', "/etc/apache2/sites-available/default-ssl.out";
		 	    while (<$din>) {
	 		    	print $dout $_;
	 	    		last if /Directory \/>/;
	 	   		}
		 	    print $dout "\n	AuthType Basic\n 	AuthName \"Authentication Required\"\n";
		 	    print $dout "	AuthUserFile /var/htpasswd\n";
		 	    print $dout "# Comment out the line below to disable password protection\n";
		 	    print $dout "	Require valid-user\n\n";
		 	    while (<$din>) {
	 		    	print $dout $_;
	 		    }
	 	    	close $dout;
	    		move "/etc/apache2/sites-available/default-ssl.out", "/etc/apache2/sites-available/default-ssl";
				$instlog .= "Apache configured for htaccess.\n";
				$restart++;
    		}
    		if (-e "/var/htpasswd") {
      			print "The htpasswd file already exists. Adding to it...\n";
 	      		print "Provide a username (single word with no spaces): ";
    	   		my $username = <>; chomp $username;
      			`htpasswd /var/htpasswd $username`;
	    	} else {
    	 		print "Provide a username (single word with no spaces): ";
       			my $username = <>; chomp $username;
	      		`htpasswd -c /var/htpasswd $username`;
		    }
		    print "Your htpassword file is '/var/htpasswd'\n";
    		print "Please see 'man htpasswd' for more information on managing htaccess users.\n";
    	} else {
    		print "htaccess skipped\n";
    	}
	    `service apache2 restart` if ($restart > 0);
		print "Please read the README and edit your miner conf file as required.\nDone! Thank you for flying IFMI!\n";
	} else { 
		print "Cant determine apache user, Bailing out!\n";
		$instlog .= "unknown apache user, bailed out.\n";
	}
	open my $lin, '>', "PM-install-log.$now";
	print $lin $instlog;
	close $lin; 
}






