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
die "please execute from the install directory.\n" if (!-f "./install-pm.pl") ;

if ((defined $ARGV[0]) && ($ARGV[0] eq "-q")) {
	my $flag = $ARGV[0];
	&doInstall($flag); 
} else { 
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
}
sub doInstall {
	my $flag = "x";;
	$flag = $_[0] if (defined $_[0]);
	use POSIX qw(strftime);
	my $now = POSIX::strftime("%Y-%m-%d.%H.%M", localtime());	
	my $instlog = "PoolManager Install Log.\n$now\n";
	print "Perl module check \n" if ($flag ne "-q");
	require RRDs;
	require YAML;
	require JSON;
	require Email::Simple;
	require Email::Sender;
	require Try::Tiny;
	print " ..all set!\n" if ($flag ne "-q");
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
			print "Copying files...\n" if ($flag ne "-q");
			#perl chown requires UID and make_path is broken, so
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
  		copy "pmgraph.pl", $appdir; 
  		copy "pmnotify.pl", $appdir;
      copy "run-poolmanager.pl", $appdir;
    	copy "sendstatus.pl", $appdir;
    	`cp themes/* $webdir/IFMI/themes`;
    	`cp images/*.png $webdir/IFMI`;
    	`chmod 0755 $appdir/*.pl`; #because windows f's up the permissions. wtf. 
    	`chmod 0755 $appdir/mcontrol`; #because windows
    	`chmod 0755 $appdir/farmview`; #because windows
    	`chmod 0755 $cgidir/*.pl`; #because windows
			`chown $apacheuser $appdir/poolmanager.conf` if (-f "$appdir/poolmanager.conf");
    	$instlog .= "files copied.\n";
		} else { 
			die "Your web directories are in unexpected places. Quitting.\n";
		}
		copy "/etc/crontab", "/etc/crontab.pre-ifmi" if (!-f "/etc/crontab.pre-ifmi");
    if (! `grep -E  ^"\* \* \* \* \* root /opt/ifmi/run-poolmanager.pl" /etc/crontab`) {
			print "Setting up crontab...\n" if ($flag ne "-q");
    	open my $cin, '>>', "/etc/crontab";
     	print $cin "* * * * * root /opt/ifmi/run-poolmanager.pl\n\n";
    	close $cin;
	    $instlog .= "crontab modified.\n";
    }
    copy "/etc/sudoers.pre-ifmi", "/etc/sudoers" if (-f "/etc/sudoers.pre-ifmi");
		copy "/etc/sudoers", "/etc/sudoers.pre-ifmi" if (!-f "/etc/sudoers.pre-ifmi");
		if (! `grep -E /opt/ifmi/mcontrol /etc/sudoers`) {
		    print "Modifying sudoers....\n" if ($flag ne "-q");
	      	open my $sin, '>>', "/etc/sudoers";
	 		print $sin "$apacheuser ALL=(root)NOPASSWD: /opt/ifmi/mcontrol,/usr/bin/htpasswd\nDefaults:$apacheuser rootpw\n$apacheuser ALL=(root) /bin/cp\n";
			close $sin;
			`chmod 0440 /etc/sudoers`;
			$instlog .= "sudoers modified.\n";
		}
		print "PoolManager attempts to set up some basic security for your web service.\n" if ($flag ne "-q");
		print "It will enable SSL and redirect all web traffic over https.\n" if ($flag ne "-q");
		if (!-f "/etc/ssl/certs/apache.crt") {
			print "First, we need to create a self-signed cert to enable SSL.\n" if ($flag ne "-q");
			print "The next set of questions is information for this cert.\n" if ($flag ne "-q");
			print "Please set the country code, and the rest of the cert quetions can be left blank.\n";
			print "Press any key to continue: ";
			my $creply = <STDIN>; 
			if ($creply =~ m/.*/) {
			    `/usr/bin/openssl req -x509 -nodes -days 1825 -newkey rsa:2048 -keyout /etc/ssl/private/apache.key -out /etc/ssl/certs/apache.crt`;
			    print "...finished creating cert.\n";
			    $instlog .= "cert created.\n";
			}
	 	} else {
    		print "...cert appears to be installed, skipping...\n" if ($flag ne "-q");
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
		`service apache2 restart` if ($restart > 0);
		print "Please read the README and edit your miner conf file as required.\nDone! Thank you for flying IFMI!\n" if ($flag ne "-q");
	} else { 
		print "Cant determine apache user, Bailing out!\n";
		$instlog .= "unknown apache user, bailed out.\n";
	}
	open my $lin, '>', "PM-install-log.$now";
	print $lin $instlog;
	close $lin; 
}






