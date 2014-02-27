Web based pool and miner manager for Linux running CGminer and clones (sgminer, vertminer, keccak, etc). Written in perl (no php). 
Originally extended from the BAMT miner web interface of gpumon/mgpumon.

* Add or Remove pools, or Switch priority, from the web GUI without stopping your miner.
* Stop/start the miner, with password protection and version/run time display.
* Stats header with Total Accepted/Rejected/Ratio, Work Util, HW errors, Uptime, Load, Free Mem.
* GPU and Pool details pages, including native graphing with persistence. 
* Miner details page with reboot control and Configuration Editor.
* Install script enables SSL redirection (and optional default page password) for security.
* Farm Overview provides status view for all nodes running PoolManager. 

See the GitHub wiki page for screenshots.

-----

Reqirements: Linux running cgminer or clone. Built and tested on litecoin-bamt 1.2. 
Packages req: Perl5 + extensions, rrdtool. 

NOTE! Installation does not check dependencies yet. This should work out of the box on BAMT, but may need some Perl modules on clean Linux installs. 

------

EASY PEASY SURE FIRE INSTALL INSTRUCTIONS: (but see the above note!)

(Doing it this way ensures all the files will have the correct permissions.)

1. ssh into your miner, so you are at the command prompt. be root (if you are user, do: sudo su - ).
1. do: wget https://github.com/starlilyth/Linux-PoolManager/archive/master.zip
1. do: unzip master.zip
1. cd to 'Linux-PoolManager-master' directory and run: ./install-pm.sh
1. cd to /opt/ifmi/ and edit poolmanager.conf as needed. In particular, you may want to change the config file save path, as PoolMananger will save the config whenever you add or remove pools. 

Please make sure the following entries are in your cgminer.conf:

    "api-listen" : true,
    "api-allow" : "W:127.0.0.1",


PoolManager installation attempts to modify /etc/sudoers to allow the web service to stop/start the miner application, modify files, and boot the machine, all as a specified user. If it fails, you will need to modify sudoers yourself with the following: 

    Defaults targetpw  
    apacheuser ALL=(ALL) /opt/ifmi/mcontrol,/bin/cp,/path/to/reboot

Where apacheuser is the user that your web service runs as, and /path/to/reboot is the path to the reboot command. 

Once installed, simply visit the IP of your miner in a browser. PoolManager enables and uses SSL (https), so be sure to open port 443 on any firewalls or routers if necessary. 

If you wish to remove PoolManager, you can run the remove-pm.sh script in the same directory you ran install-pm.sh

-----

FAQ: 
Q: Why doesnt PoolManager let me: save a pool as X priority/switch to a dead pool/save priority list on restart/have pool aliases?
A: PoolManager only mirrors what cgminer can do, via the API, these are things that cgminer doesnt do, and are non-trivial to implement yet. As development progresses in some other areas, some of this may be easier, and I will add it. 

-----

Absolutely NO hidden donate code! 
You can trust the IFMI brand to never include any kind of auto donate or hash theft code.

If you love it, please donate!

BTC: 1JBovQ1D3P4YdBntbmsu6F1CuZJGw9gnV6

LTC: LdMJB36zEfTo7QLZyKDB55z9epgN78hhFb

Donate your hashpower directly at http://wafflepool.com/