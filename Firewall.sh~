#!/bin/bash

IPT="/sbin/iptables"

####USER CONFIG SECTION ###
firewallHost="192.168.10.1"
internalHost="192.168.10.2"
intOut="em1"
intIn="p3p1"
TCPallow="80,443"
UDPallow="53,67,68"
ICMPallow=( 0 3 8 )

#### END USER CONFIG SECTION ###

#Flush any existing rules
$IPT -X
$IPT -F

#Default policies
$IPT -P INPUT DROP -m comment --comment "Default policy INPUT DROP"
$IPT -P FORWARD DROP -m comment --comment "Default policy FORWARD DROP"
$IPT -P OUTPUT DROP -m comment --comment "Default policy OUTPUT DROP"

#Drop all packets destined for FIREWALL from the outside
	$IPT -A INPUT -i $intOut -d $firewallHost -j DROP -m comment --comment "Drop all packets destined for firewall from outside"

#Block all packets with a source address from outside that has a source address of internal network
	$IPT -A FORWARD -s 192.168.10.0/24 -i $intOut -j DROP -m comment --comment "Block packet with same source add as internal network"

#Block ALL TCP packets with SYN-FIN bits set
	$IPT -A FORWARD -p TCP -i $intOut -o $intIn --tcp-flags SYN,FIN SYN,FIN -j DROP -m comment --comment "Do not allow SYN-FIN"

#Block all external traffic directed to custom ports
	$IPT -A FORWARD -p tcp -i $intOut -o $intIn --dport 32768:32775 -j DROP -m comment --comment "DROP ALL TCP TRAFFIC TO 32768-32775" 
	$IPT -A FORWARD -p tcp -i $intOut -o $intIn --dport 137:139 -j DROP -m comment --comment "DROP ALL TCP TRAFFIC TO 137-139" 
	$IPT -A FORWARD -p tcp -i $intOut -o $intIn -m multiport --dport 111,515 -j DROP -m comment --comment "DROP ALL TCP TRAFFIC TO 111,515" 
	$IPT -A FORWARD -p udp -i $intOut -o $intIn --dport 32768:32775 -j DROP -m comment --comment "DROP ALL UDP TRAFFIC TO 32768-32775"
	$IPT -A FORWARD -p udp -i $intOut -o $intIn --dport 137:139 -j DROP -m comment --comment "DROP ALL UDP TRAFFIC TO 32768-32775"


#Block all TELNET
	$IPT -A FORWARD -p TCP --sport 23 -j DROP -m comment --comment "DROP ALL TELNET TCP"
	$IPT -A FORWARD -p TCP --dport 23 -j DROP -m comment --comment "DROP ALL TELNET TCP"

#Accept Fragments (TESTING DOESNT WORK)
	$IPT -A FORWARD -f -j ACCEPT -m state --state new,established

#Accept all inbound/outbound TCP on custom ports
	$IPT -A FORWARD -p TCP -m multiport --dport $TCPallow -j ACCEPT -m state --state new,established
	$IPT -A FORWARD -p TCP -m multiport --sport $TCPallow -j ACCEPT -m state --state new,established

#Accept all inbound/outbound UDP on custom ports
	$IPT -A FORWARD -p UDP -m multiport --dport $UDPallow -j ACCEPT
	$IPT -A FORWARD -p UDP -m multiport --sport $UDPallow -j ACCEPT

#Allow ports 20,21,22 for SSH/FTP rules
	$IPT -A FORWARD -p TCP -m multiport --dport 20,21,22 -j ACCEPT -m state --state new,established
	$IPT -A FORWARD -p TCP -m multiport --sport 20,21,22 -j ACCEPT -m state --state new,established

#Custom SSH and FTP rules
$IPT -A PREROUTING -m multiport -t mangle -p tcp --sport 20,21,22 \
  -j TOS --set-tos Minimize-Delay -m comment --comment "SSH and FTP Min Delay"
$IPT -A PREROUTING -m multiport -t mangle -p tcp --sport 20,21 \
  -j TOS --set-tos Maximize-Throughput -m comment --comment "FTP Max Throughput"

#Accept all ICMP on custom packet types

for i in "${ICMPallow[@]}"
do
	:	
	$IPT -A FORWARD -p ICMP -i $intOut -o $intIn --icmp-type $i -j ACCEPT -m comment --comment "ALLOW ICMP"
	$IPT -A FORWARD -p ICMP -i $intIn -o $intOut --icmp-type $i -j ACCEPT -m comment --comment "ALLOW ICMP"
	echo "done $i"	
done

#Block all SYN TO high ports
	$IPT -A FORWARD -p TCP --tcp-flags SYN SYN ! --dport 1:1024 -j DROP


echo "New IPTABLES SET";
service iptables save
service iptables restart

iptables -L -v -x -n

