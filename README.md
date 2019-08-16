Git repository for code arising from the work chronicled on https://hackingthenetgearorbi.wordpress.com/

The aim of this project is to create a simple installer for my project to unleash the power of Linux underlying the NetGear Orbi.

The first thing one would need to do is to enable the Orbi's telnet interface. One way to do this is from the Orbi's hidden debug page at http://yourOrbi'sIPaddress/debug_detail.htm. Another way is provided by the telnetenable program (discussed here:  https://openwrt.org/toh/netgear/telnet.console, and downloadable from here: https://github.com/insanid/NetgearTelnetEnable/raw/master/binaries/windows/telnetEnable.exe).

Once telnet is enabled, the installation method I'm providing here requires Nodejs (https://nodejs.org) and the expect-telnet, netcat, and tar modules (install using npm: "npm install expect-telnet", "npm install netcat", and "npm install tar".

The installation program, orbi.js, will ask for the (admin) password (the same that you use on the Orbi's web UI), try to guess the IP address of your Orbi(set it manually if you aren't running on a LAN with a 255.255.255.0 netmask and your Orbi located at xxx.xxx.xxx.1), transfer some scripts over, probe for unused/empty partitions and ask which one you want to install the project on. It will then format and mount the partition (on /usr/local), do some basic setup, start the ssh server, and co-opt the Orbi's bitdefender system startup script so that the whole thing will start up automatically after reboots.

CAUTION: This is a work in progress. There's a potential for data loss. There's a potential for firmware corruption and I'm not prepared to give assistance on unbricking your Orbi.