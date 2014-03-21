Web based pool and miner manager for Linux running CGminer and clones (sgminer, vertminer, keccak, etc). Written in perl (no php). 
Originally extended from the BAMT miner web interface of gpumon/mgpumon.

* Add or Remove pools, or Switch priority, from the web GUI without stopping your miner.
* Stop/start the miner, with password protection and version/run time display.
* Stats header with Total Accepted/Rejected/Ratio, Work Util, HW errors, Uptime, Load, Free Mem.
* GPU and Pool details pages, including native graphing with persistence. 
* Miner details page with reboot control, SSH to Host link and Configuration Editor.
* Install script enables SSL redirection (and optional default page password) for security.
* Farm Overview, including miner versions, active pools, and last page refresh time.
* Easy CSS theming, with several themes included. 
* GUI Settings Page - no need to edit a settings file
* NEW! PoolManager can now be configured to send an email when GPU alert conditions are met, including sick and dead status, hardware errors, and stopped/hung miner, along with all the previously available alert settings, and a new Fan High setting. 

See the GitHub wiki page for screenshots.

-----

Reqirements: Linux running cgminer or clone. Built and tested on litecoin-bamt 1.2.
This should work out of the box on BAMT, but will need the following Perl modules on clean Linux installs: 

* libjson-perl
* libyaml-perl 
* librrds-perl

and additionally for email notifications..
* libemail-simple-perl
* libemail-sender-perl
* libtry-tiny-perl

------

EASY PEASY SURE FIRE INSTALL INSTRUCTIONS: (but see the above note!)

(Doing it this way ensures all the files will have the correct permissions.)

1. ssh into your miner, so you are at the command prompt. be root (if you are user, do: sudo su - ).
1. do: wget https://github.com/starlilyth/Linux-PoolManager/archive/master.zip
1. do: unzip master.zip
1. cd to 'Linux-PoolManager-master' directory and run: ./install-pm.pl

Please make sure the following entries are in your cgminer.conf:

    "api-listen" : true,
    "api-allow" : "W:127.0.0.1",

Once installed, simply visit the IP of your miner in a browser. PoolManager enables and uses SSL (https), so be sure to open port 443 on any firewalls or routers if necessary. 

UPGRADING IS JUST AS EASY!
  Do all the steps as above.

Install Notes: 
PoolManager installation attempts to modify /etc/sudoers to allow the web service to stop/start the miner application, modify files, and boot the machine, all as a specified user. This works on BAMT and most other distros, but if it fails you will need to modify sudoers yourself with the following: 

    Defaults targetpw  
    apacheuser ALL=(ALL) /opt/ifmi/mcontrol,/bin/cp,/path/to/reboot

Where apacheuser is the user that your web service runs as, and /path/to/reboot is the path to the reboot command. 

If you wish to remove PoolManager, you can run the remove-pm.sh script in the same directory you ran install-pm.sh

EMAIL NOTES: You wont be able to use a non SSL/TLS configuration unless you install a local mail server. BAMT comes with no proper MTA, just 'esmtp' which is an outbound only SMTP connector to a real mail server (like Gmail). BAMT and true clones have the necessary modules to use this with a TLS connection, but NOT plain SSL.
Gmail works with port 587 and TLS. 

-----

FAQ: 

Q1: I cant get to my miner page anymore! 

A1: PoolManager changes your Apache configuration to use https, which is on port 443, not port 80. Please make sure you have port 443 open on any firewalls or routers between you and your miner. 

Q2: FarmView doesnt work/shows no/bad or double status in BAMT

A2: Make sure mgpumon and broadcast are stopped. Edit bamt.conf, set do_mgpumon to 0 and set do_bcast_status to 0. If you need to use mgpumon, put it on a different port. 

Q3: How can I see my miner page/farmview remotely?

A3: In general, you will either have to allow access to your miner from the internet, or you can export the farmview.html page to an internet web server (probably with some combination of rsync/scp and cron). The specifics will depend on your setup and needs, and are beyond the scope of this document. 

Q4: My graphs are messed up after updating. 

A4: Press 'Clear All Graphs' on the settings page. It will take about ten minutes for the graphs to clear and start redrawing. 

Q5: How do I change the default page password? 

A5: Your htpasswd file is in /var, so you can do: 'htpasswd /var/htpasswd username', where username is the name you want to manage. 

Q6: How do I disable the default page password? I dont want it anymore.  

A6: Edit /etc/apache2/sites-available/default-ssl and comment out "Require valid-user", near the top. Then do 'apachectl restart'. 

Q7: Why doesnt PoolManager let me: save a pool as X priority/switch to a dead pool/save priority list on restart?

A7: PoolManager only mirrors what cgminer can do, via the API, these are things that cgminer doesnt do, and are non-trivial to implement yet. As development progresses in some other areas, some of this may be easier, and I will add it. 

-----

Absolutely NO hidden donate code! 
You can trust the IFMI brand to never include any kind of auto donate or hash theft code.

If you love it, please donate!

BTC: 1JBovQ1D3P4YdBntbmsu6F1CuZJGw9gnV6

LTC: LdMJB36zEfTo7QLZyKDB55z9epgN78hhFb

Donate your hashpower directly at http://wafflepool.com/
