#!/bin/sh

DIR=/usr/local/adblock
CONF=$DIR/adblock.conf
TMPLIST=$DIR/tmp/tmplist
echo > $TMPLIST
BLOCKLIST=$DIR/blocklist
echo > $BLOCKLIST
SOURCENAME=
URL=
CONFIG=
ENABLED=0
OPTION=
FILTER=
rm /usr/bin/wget
cat<<EOF > /usr/bin/wget
#!/bin/sh
/usr/bin/wget-ssl --no-check-certificate \$@
EOF
chmod a+x /usr/bin/wget
while read -r line; do
	FIRST=$( echo $line | cut -f 1 -d ' ' )
	SECOND=$( echo $line | cut -f 2 -d ' ' )
	THIRD=$( echo $line | cut -f 3- -d ' ' )
	if [ $FIRST ] && [ $FIRST = 'config' ] && \
	   [ $SECOND ] && [ $SECOND = 'source' ]; then
		SOURCENAME=$THIRD
	fi
	if [ $SOURCENAME ] && \
	   [ $FIRST ] && [ $FIRST = 'option' ] && \
	   [ $SECOND ] && [ $SECOND = 'enabled' ] && \
	   [ $THIRD ] && [ $(echo $THIRD | grep 1) ]; then
		echo $SOURCENAME is enabled
		ENABLED=1
	fi
        if [ $SOURCENAME ] && \
	   [ $ENABLED -eq 1 ] && \
           [ $FIRST ] && [ $FIRST = 'option' ] && \
           [ $SECOND ] && [ $SECOND = 'adb_src' ] && \
           [ $THIRD ]; then
		URL=$THIRD
	fi
        if [ $SOURCENAME ] && \
           [ $ENABLED -eq 1 ] && \
           [ $FIRST ] && [ $FIRST = 'option' ] && \
           [ $SECOND ] && [ $SECOND = 'adb_src_rset' ] && \
           [ ! -z "$THIRD" ]; then
		eval "FILTER=\"${THIRD}\""
		if [ $SOURCENAME == "'blacklist'" ]; then
			cat $DIR/adblock.blacklist >> $TMPLIST
		else
			eval "wget -O - $URL | awk ${FILTER} >> $TMPLIST"
		fi
                SOUCENAME=
		URL=
		ENABLED=0
		FILTER=
        fi
done < $CONF

while read -r hostname; do
	if [ $hostname ]; then
		echo 127.0.0.1 $hostname >> $BLOCKLIST
	fi
done < $TMPLIST
