#!/bin/ash

DEVICE=br0
COUNT=0
until ( ethtool br0 | grep yes > /dev/null )
do
    COUNT=$((COUNT+1))
    if ( [ $COUNT -gt 10 ] ); then
        echo $DEVICE isn\'t becoming active: exiting
    fi
    sleep 5
    COUNT=$((COUNT+1))
done

if [ -d /etc/dropbear ]; then
  echo /etc/dropbear already exists
else
  if [ ! -d /usr/local/dropbear/etc/dropbear ]; then
    mkdir /usr/local/dropbear/etc/dropbear
  fi
  cp -a /usr/local/dropbear/etc/* /etc
fi
chmod 0700 /etc/dropbear
chmod 0600 /etc/dropbear/*
if [ ! -f /etc/dropbear/dropbear_rsa_host_key ]; then
	/usr/local/dropbear/usr/bin/dropbearkey -t rsa -f /etc/dropbear/dropbear_rsa_host_key
	cp -a /etc/dropbear/dropbear_rsa_host_key /usr/local/dropbear/etc/dropbear/dropbear_rsa_host_key
fi

ln -s /usr/local/dropbear/usr/sbin/dropbear /usr/sbin/dropbear
ln -s /usr/local/dropbear/usr/sbin/dropbear /usr/bin/ssh
ln -s /usr/local/dropbear/usr/sbin/dropbear /usr/bin/dbclient
ln -s /usr/local/dropbear/usr/sbin/dropbear /usr/bin/scp

if [ -f /usr/libexec/sftp-server ]; then
  echo /usr/libexec/sftp-server already exists
else
  if [ -d /usr/libexec ]; then
    echo /usr/libexec already exists
  else
    mkdir /usr/libexec
  fi
  ln -s /usr/local/dropbear/usr/libexec/sftp-server /usr/libexec
fi

if [ -f /etc/device_tables/etc/dropbear-local.sh ]; then
  /etc/device_tables/etc/dropbear-local.sh
fi

if ( pidof dropbear > /dev/null ); then
    echo dropbear is running
else
    /usr/sbin/dropbear -R
fi
