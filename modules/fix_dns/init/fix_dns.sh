#!/bin/sh

UPDATE_INTERVAL=15
BLOCKLIST="/usr/local/adblock/blocklist"
DHCPHOSTLIST="/tmp/dhcpd_hostlist"

echo "#!/bin/sh

. /usr/local/lib/networkfunctions.sh
udhcpd_md5=0
blocklist_md5=0

updatehost () {
	echo beginning update...
        udhcpd_md5=\`md5sum $DHCPHOSTLIST | cut -f 1 -d ' '\`
        blocklist_md5=\`md5sum $BLOCKLIST | cut -f 1 -d ' '\`

        UPDATETMP=\`/bin/mktemp\`
	if [ -f /tmp/device_tables/etc/static_hosts ]; then
            # /tmp/device_tables/etc/static_hosts *may* contain a list of
            # hosts to have as static routes, use traditional /etc/hosts
            #format
            cat /tmp/device_tables/etc/static_hosts >> \$UPDATETMP
        fi
        list_all_hostnames >> \$UPDATETMP
        uniq < \$UPDATETMP >> /etc/hosts

	cat $BLOCKLIST >> /etc/hosts

	echo ...forcing dnsmasq to reload
        killall -SIGHUP dnsmasq
        rm \$UPDATETMP
}

initialize () {
	name=\`basename \"\$0\"\`
	mypid=\$\$
	pid=\`pidof \$name\`
	if [ ! \"\$mypid\" == \"\$pid\" ]; then
		for i in \$pid; do
			if [ \$i != \$mypid ]; then
				echo killing pid \$i
				kill \$i
			fi
		done
	fi
}

initialize
updatehost
while ( true ); do
	tmpmd5=\`md5sum $DHCPHOSTLIST | cut -f 1 -d ' '\`
	if [ \$udhcpd_md5 != \$tmpmd5 ]; then
 		udhcpd_md5=\$tmpmd5
 		echo change detected.
 		updatehost
	fi
	tmpmd5=\`md5sum $BLOCKLIST | cut -f 1 -d ' '\`
 	if [ \$blocklist_md5 != \$tmpmd5 ]; then
		block_md5=\$tmpmd5
		echo change detected.
 		updatehost
	fi
        trap updatehost HUP
	sleep $UPDATE_INTERVAL
done" > /tmp/updatehosts.sh

chmod a+x /tmp/updatehosts.sh
/tmp/updatehosts.sh &
sed -e 's/#*no-hosts/#no-hosts/' < /rom/etc/dnsmasq.conf > /etc/dnsmasq.conf
#echo $"$STATIC" > /etc/hosts
#echo addn-hosts=$BLOCKLIST >> /etc/dnsmasq.conf
#echo addn-hosts=$DHCPHOSTLIST >> /etc/dnsmasq.conf
/etc/init.d/dnsmasq restart
