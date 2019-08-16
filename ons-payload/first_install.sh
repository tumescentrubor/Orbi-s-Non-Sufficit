#!/bin/sh

THIS_IS_A_SATELLITE=0

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
	if ( blkid $LOCAL_DISK ); then
		echo $LOCAL_DISK alread has some sort of stuff on it, exiting
		exit;
	fi
fi

mkdir $LOCAL_DIR
mkfs.ext4 $LOCAL_DISK
mount $LOCAL_DISK $LOCAL_DIR
mkdir $LOCAL_DIR/init

if [ -f "/tmp/mnt/bitdefender/bin/bd" ]; then
	echo going to install our initialization script in place of
	echo the bitdefender master process at /tmp/mnt/bitdefender/bin/bd
	if [ -f "/tmp/mnt/bitdefender/bin/bd.bak" ]; then
		echo /tmp/mnt/bitdefender/bin/bd.bak already exists,
		echo not backing up /tmp/mnt/bitdefender/bin/bd
	else
		echo mv /tmp/mnt/bitdefender/bin/bd /tmp/mnt/bitdefender/bin/bd.bak
	fi
	sed -e "s%LOCAL_DISK%$LOCAL_DISK%g" -e "s%LOCAL_DIR%$LOCAL_DIR%g" < /tmp/device_tables/ons-payload/bd > /tmp/mnt/bitdefender/bin/bd
else
	echo assuming this is an Orbi satellite
	cp /tmp/device_tables/bootstrap.sh $LOCAL_DIR/
	THIS_IS_A_SATELLITE=1
fi

cp -a /tmp/device_tables/ons-payload/modules/* $LOCAL_DIR
cp -a /tmp/device_tables/ons-payload/lib $LOCAL_DIR

for d in $LOCAL_DIR/*; do
	if [ -d "$d/init" ]; then
		ln -s $d/init/* $LOCAL_DIR/init
	fi
	if [ -d "$d/lib" ]; then
	    ln -s $d/lib/* $LOCAL_DIR/lib
	fi
	if [ -f $LOCAL_DIR/init/start_dropbear.sh ]; then
	    $LOCAL_DIR/init/start_dropbear.sh
	    echo Dropbear SSH server is now running
	    echo \(it may take a short wait to start up
	    echo if it needs to generate keys for itself\)
	fi
done


