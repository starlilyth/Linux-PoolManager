Web based pool and miner manager for Linux running CGminer and clones. Written in perl (no php). 
Originally extended from the BAMT miner web interface of gpumon/mgpumon.

* Add or Remove pools, or Switch priority, from the web GUI without stopping your miner.
* Stop/start the miner, with password protection and version/run time display.
* Stats header with Total Accepted/Rejected/Ratio, Work Util, HW errors, Uptime, Load, Free Mem.
* GPU and Pool details pages, including native graphing with persistence. 
* Miner details page with reboot control and Configuration Editor.
* Install script enables SSL redirection (and optional default page password) for security.
* Farm Overview provides status view for all nodes running PoolManager (Not yet available in this version!)

See the wiki page for screenshots.

-----

Reqirements: Linux running cgminer or clone. Built and tested on litecoin-bamt 1.2. 
Packages req: Perl5 + extensions, rrdtool, Apache w/SSL and mod_rewrite, other stuff I am sure. 


NOTE!! NOTE!! NOTE!!! 

    THIS VERSION IS NOT COMPLETE! I am porting this from a distro dependency, so many things are broken still, including FarmView. 

PROCEED AT YOUR OWN RISK!


------

EASY PEASY SURE FIRE INSTALL INSTRUCTIONS: (WHICH ARE PROBABLY BROKEN)

(Doing it this way ensures all the files will have the correct permissions.)

1. ssh into your miner, so you are at the command prompt. be root (if you are user, do: sudo su - ).
2. do: wget https://github.com/starlilyth/Linux-PoolManager/archive/master.zip
3. do: unzip master.zip
4. cd to 'Linux-PoolManager-master' directory and run: ./install-pm.sh
5. Please make sure the following entries are in your cgminer.conf:

    "api-listen" : true,
    "api-port" : "4028",
    "api-allow" : "W:127.0.0.1",

PoolManager installation attempts to modify /etc/sudoers to allow the web service to stop/start the miner application, modify files, and boot the machine, all as a specified user. If it fails, you will need to modify sudoers yourself with the following: 

    Defaults targetpw  
    apacheuser ALL=(ALL) /opt/ifmi/mcontrol,/bin/cp,/path/to/reboot

Where apacheuser is the user that your web service runs as, and /path/to/reboot is the path to the reboot command. 

-----

Absolutely NO hidden donate code! 
You can trust the IFMI brand to never include any kind of auto donate or hash theft code.

If you love it, please donate!

BTC: 1JBovQ1D3P4YdBntbmsu6F1CuZJGw9gnV6

LTC: LdMJB36zEfTo7QLZyKDB55z9epgN78hhFb

Donate your hashpower directly at http://wafflepool.com/