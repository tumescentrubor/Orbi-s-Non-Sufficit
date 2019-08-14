#!/bin/sh

if ( iptables -L net2loc  | grep "tcp dpt:ssh state NEW recent: SET name: DEFAULT side: source" > /dev/null ); then
    echo rule 1 is already here
else
    iptables -I net2loc -p tcp --dport 22 -m state --state NEW -m recent --set
fi
if ( iptables -L net2loc | grep "tcp dpt:ssh state NEW recent: UPDATE seconds: 60 hit_count: 4 name: DEFAULT side: source" > /dev/null ); then
    echo rule 2 is already here
else
    iptables -I net2loc -p tcp --dport 22 -m state --state NEW -m recent --update --seconds 60 --hitcount 4 -j DROP
fi

