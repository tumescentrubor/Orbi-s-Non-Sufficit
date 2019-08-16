#!/bin/sh

if [ $1 ] && [ $1 = 'list_functions' ]; then
  #echo this is $0
  while read line; do
    echo $line | grep -E "^\w+\(\)" | sed -e "s/{//"
  done < $0
fi

lc() {
  while read LINE; do
    echo $LINE | tr '[ABCDEFGHIJKLMNOPQRSTUVWXYZ]' '[abcdefghijklmnopqrstuvwxyz]'
  done
}

ping_check() {
    TIMES=3
    if [ $2 ]; then
      TIMES=$2
    fi
    if [ $1 ] && [ $(valid_ip_address $1) ]; then 
      RESULT=$( ping -c $TIMES -w 2 $1 | tail -n 1 )
      if ( echo $RESULT | grep round-trip > /dev/null ); then
        echo $RESULT | cut -f 5 -d '/' | cut -f 1 -d ' '
      elif ( echo $RESULT | grep "packet loss" > /dev/null ); then
        echo failed
      else
        echo indeterminate result
      fi
    else
      echo $1 is not a valid ip address
    fi
}

valid_ip_address() {
    if ( echo $1 | grep -E '^[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}$' > /dev/null ); then
      echo true
    else
      echo false
    fi
}

line_format_hostnames() {
  TMP=`mktemp`
  while read LINE; do
    echo $LINE >> $TMP
  done 
  LINES=$( wc -l $TMP | cut -f 1 -d ' ')
  COUNT=1
  for i in $( cat $TMP | tr ' ' ':' ); do
    echo -ne $i
    if [ $COUNT -lt $LINES ]; then
      echo -ne ", "
    fi
    COUNT=$(($COUNT+1))
  done
  echo
  rm $TMP
}

list_interesting_hostnames() {
  if [ -f /tmp/device_tables/etc/saved_mac_hashes ]; then
    ip neighbor > /tmp/ip_neighbor
    while read -r LINE; do

      MAC=$(echo $LINE | cut -f 1 -d ';'  )
      NAME=$(echo $LINE | cut -f 2 -d ';'  )
      if ( grep -i $MAC /tmp/ip_neighbor > /dev/null ); then
        for IP in $( grep -i $MAC /tmp/ip_neighbor | cut -f 1 -d ' ' ); do
          if [ $( valid_ip_address $IP ) = 'true' ]; then
            echo $IP $NAME
          fi
        done
      fi

    done < /tmp/device_tables/etc/saved_mac_hashes
    #rm /tmp/ip_neighbor
  fi
}

list_all_hostnames() {
  TMP=`mktemp`
  while read -r LINE; do
    echo $( echo $LINE | cut -f 2 -d ';' ) $( echo $LINE | cut -f 3 -d ';' | lc ) >> $TMP
  done < /tmp/udhcpd_clients
  list_interesting_hostnames >> $TMP
  cat $TMP | uniq
  rm $TMP
}

list_hostnames_in_group() {
  TMP1=`mktemp`
  list_all_hostnames > $TMP1
  MATCHLINE="`grep $1 /tmp/device_tables/etc/networkgroups | cut -f 1 -d ';' | tr '\n' ' ' )`"
  while read -r LINE; do
    NAME=$( echo $LINE | cut -f 2 -d ' ' | lc )
    IP=$( echo $LINE | cut -f 1 -d ' ' )
    if ( echo $MATCHLINE | grep $NAME > /dev/null ); then
      echo $IP $NAME
    fi
  done < $TMP1
  rm $TMP1
}

remove_address_from_vpn() {
    VPN_HOST=''
    if [ $1 ]; then
        if ( echo $1 | grep -E '^[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}$' > /dev/null ); then
            VPN_HOST=$1
        elif [ $1 = "all" ]; then
            VPN_HOST="all"
        else
            echo $1 is not a valid ip address
            return
        fi
    fi
    if [ $dev ] && [ $route_vpn_gateway ]; then
      if [ $VPN_HOST = "all" ]; then
        VPN_HOST=$( list_all_vpn_hosts | tr '\n' ' ' )
      fi
      for host in $VPN_HOST; do
        if ( ip rule list | grep "from $host lookup vpn" > /dev/null ); then
          echo removing traffic from $host across vpn \($dev\)
          ip rule del from $host table vpn
        else
          echo no such rule for host $VPN_HOST
          echo exiting...
          return
        fi
      done
      CURRENTLY_IN_VPN_GROUP=`ip rule list | grep "lookup vpn" | cut -f 2 -d ' ' | tr '\n' ' '`
      if [ $( echo $CURRENTLY_IN_VPN_GROUP | wc -m ) -lt 4 ]; then
        `ip rule list | grep "lookup vpn" | cut -f 2 -d ' ' | tr '\n' ' '`
        echo removing last host from vpn routing group
        ip route del default via $route_vpn_gateway dev $dev table vpn
      fi
    else
      echo something failed getting variables
      return
    fi
}

