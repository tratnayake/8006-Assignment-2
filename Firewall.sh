#!/bin/bash

IPT="/sbin/iptables"

####USER CONFIG SECTION ###
firewallHost="192.168.10.1"
internalHost="192.168.10.2"
intOut="em1"
intIn="p3p1"
TCPallow="80,443,5000"
UDPallow="53,67,68,80,500"
ICMPallow=( 0 3 8 )

#### END USER CONFIG SECTION ###

#Flush any existing rules
$IPT -X
$IPT -F

#Default policies
$IPT -P INPUT DROP -m comment --comment "Default policy INPUT DROP"
$IPT -P FORWARD DROP -m comment --comment "Default policy FORWARD DROP"
$IPT -P OUTPUT DROP -m comment --comment "Default policy OUTPUT DROP"

#Allow DNS for FIREWALLHOST
	#Allow going OUT to port 53 (initiating a DNS request)
	$IPT -A OUTPUT -p UDP --dport 53 -j ACCEPT
	#Allow coming IN FROM port 53 (DNS reply)
	$IPT -A INPUT -p UDP --sport 53 -j ACCEPT
	#Factor for TCP in case UDP times out.
	$IPT -A OUTPUT -p TCP --dport 53 -j ACCEPT
	$IPT -A INPUT -p TCP --sport 53 -j ACCEPT

#Allow DHCP for FIREWALLHOST
	$IPT -A OUTPUT -p UDP --dport 68 -j ACCEPT
	$IPT -A INPUT -p UDP --sport 68 -j  ACCEPT
	$IPT -A OUTPUT -p TCP --dport 68 -j ACCEPT
	$IPT -A INPUT -p TCP --sport 68 -j  ACCEPT

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
$IPT -A PREROUTING -t mangle -p tcp --sport 22 \
  -j TOS --set-tos Minimize-Delay
$IPT -A PREROUTING -t mangle -p tcp --sport 21 \
  -j TOS --set-tos Minimize-Delay
$IPT -A PREROUTING -t mangle -p tcp --sport 20 \
  -j TOS --set-tos Maximize-Throughput

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

