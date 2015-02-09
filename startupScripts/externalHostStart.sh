#! /bin/bash

echo "EXTERNAL HOST (TEST) MACHINE STARTUP SCRIPT"

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

echo "What is the IP of your firewall machine that will be used as the gateway?"

read $firewallIP

route add -net 192.168.10.0/24 gw $firewallIP

echo "Internal route added!"