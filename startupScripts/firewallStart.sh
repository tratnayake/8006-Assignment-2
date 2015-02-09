#! /bin/bash

echo "FIREWALL MACHINE STARTUP SCRIPT"

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


echo "What is your IP?"
read $localIP
echo "Your IP is $localIP"

ifconfig p3p1 192.168.10.1 up
echo "P3P1 up"

echo "1" >/proc/sys/net/ipv4/ip_forward 

route add -net 192.168.0.0 netmask 255.255.255.0 gw $localIP
echo "Current network routing rules set"

route add -net 192.168.10.0/24 gw 192.168.10.1 
echo "Interneal network routing rules set"

echo "Firewall Machine Startup complete!"

ifconfig