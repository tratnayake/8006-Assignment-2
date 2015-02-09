#! /bin/bash

#Flush any existing rules
$IPT -X
$IPT -F

#Default policies
$IPT -P INPUT ACCEPT
$IPT -P FORWARD ACCEPT
$IPT -P OUTPUT ACCEPT

#Flush NAT rules if they exist
$IPT -t nat -F
$IPT -t nat -X


service iptables save
service iptables restart

iptables -L -v -x -n

echo "FIREWALLS RESET!"