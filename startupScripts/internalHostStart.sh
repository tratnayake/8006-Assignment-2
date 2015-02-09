#! /bin/bash

echo "INTERNAL HOST MACHINE STARTUP SCRIPT"

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

echo "FIREWALL (if existant) RESET!"


ifconfig em1 down
echo "em1 down"

ifconfig p3p1 192.168.10.2 up
echo "p3p1 up"

route add default gw 192.168.10.1
echo "default gw firewall added"

echo 'Inernal Host Machine Startup Script Finished!'

ifconfig 