#!/bin/sh

if [ -z $1 ] || [ -z $2 ]; then
    echo usage: $0 \<directory\> \<partition\>
    exit
fi

if [ -d $1 ]; then
	echo directory "$1" already exists. exiting
	exit;
else
	LOCAL_DIR=$1
fi
if [ ! -b $2 ]; then
	echo block file $2 doesn\'t exist, exiting
	exit;
else
	LOCAL_DISK=$2
fi

if [ ! -f "/opt/bitdefender/bin/bd" ]; then
	echo file /opt/bitdefender/bin/bd doesn\'t exist. this breaks our whole plan, exiting
	exit;
else
	echo mv /opt/bitdefender/bin/bd /opt/bitdefender/bin/bd.bak
	sed -e "s%LOCAL_DISK%$LOCAL_DISK%g" -e "s%LOCAL_DIR%$LOCAL_DIR%g" < /tmp/device_tables/ons-payload/bd
fi
