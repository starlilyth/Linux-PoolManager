Web based pool and miner manager for Linux running CGminer and clones, in perl (no php). 
Originally extended from the BAMT miner web interface.

    Add or Remove pools, or Switch priority, from the web GUI without stopping your miner.
    Stop/start the miner, with password protection and version/run time display.
    Extra stats in the header (Work Util, HW errors, Uptime, Load, Free Mem).
    Refactored GPU stats on overview and details pages. Pool details page.
    Miner details page with reboot control and Configuration Editor.
    Install script enables SSL redirection (and optional default page password) for security.
    Native graphing with better details - no Munin
    Farm Overview (mgpumon) is much improved with more information in less space. (Not yet available in this version!)

See the wiki page for screenshots.

Reqirements: Linux running cgminer or clone. Built and tested on litecoin-bamt 1.2. 


NOTE!! NOTE!! NOTE!!! 
    THIS VERSION IS NOT COMPLETE! I am porting this from a distro dependency, so many things are broken still, including mgpumon and miner control. 
        PROCEED AT YOUR OWN RISK!

EASY PEASY SURE FIRE INSTALL INSTRUCTIONS: (WHICH ARE PROBABLY BROKEN)

(Doing it this way ensures all the files will have the correct permissions.)

    ssh into your miner, so you are at the command prompt. be root (if you are user, do: sudo su - ).
    do: wget https://github.com/starlilyth/Linux-PoolManager/archive/master.zip
    do: unzip master.zip
    cd to 'Linux-PoolManager-master' directory and run: ./install-pm.sh
    add an API line to your cgminer.conf. (please see the README).

Absolutely NO hidden donate code! You can trust the IFMI brand to never include any kind of auto donate or hash theft code.

If you love it, please donate!

BTC: 1JBovQ1D3P4YdBntbmsu6F1CuZJGw9gnV6

LTC: LdMJB36zEfTo7QLZyKDB55z9epgN78hhFb

Donate your hashpower directly at http://wafflepool.com/