#!/bin/bash

IPT="/sbin/iptables"

####USER CONFIG SECTION ###
IPfw="192.168.0.14"
IPhost="192.168.10.2"
intOut="em1"
intIn="p3p1"
TCPallow="6000,2000"
UDPallow="7000,3000"
ICMPallow="8"

#### END USER CONFIG SECTION ###

#Flush any existing rules
$IPT -X
$IPT -F

#Default policies
$IPT -P INPUT DROP
$IPT -P FORWARD DROP
$IPT -P OUTPUT DROP



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

#Block ALL TCP packets with SYN-FIN bits set (TESTING DOESNT WORK)
	$IPT -A FORWARD -p TCP --tcp-flags SYN,FIN SYN,FIN -j DROP

#Block all packets with a source address from outside that has a source address of internal network **HAS TO BE BELOW SYN/FIN STUFF **
	#$IPT -A FORWARD -s 192.168.10.0/255.255.255.0 -j DROP

#Block all external traffic directed to custom ports
	$IPT -A FORWARD -p tcp -i $intOut -o $intIn --dport 32768:32775 -j DROP
	$IPT -A FORWARD -p tcp -i $intOut -o $intIn --dport 137:139 -j DROP
	$IPT -A FORWARD -p tcp -i $intOut -o $intIn -m multiport --dport 111,515 -j DROP
	$IPT -A FORWARD -p udp -i $intOut -o $intIn --dport 32768:32775 -j DROP
	$IPT -A FORWARD -p udp -i $intOut -o $intIn --dport 137:139 -j DROP
	$IPT -A FORWARD -p udp -i $intOut -o $intIn -m multiport --dport 111,515 -j DROP
	$IPT -A FORWARD -p udplite -i $intOut -o $intIn -m multiport --dport 32768:32775 -j DROP
	$IPT -A FORWARD -p udplite -i $intOut -o $intIn -m multiport --dport 137:139 -j DROP
	$IPT -A FORWARD -p udplite -i $intOut -o $intIn -m multiport --dport 111,515 -j DROP
	$IPT -A FORWARD -p sctp -i $intOut -o $intIn --dport 32768:32775 -j DROP
	$IPT -A FORWARD -p sctp -i $intOut -o $intIn --dport 137:139 -j DROP
	$IPT -A FORWARD -p sctp -i $intOut -o $intIn -m multiport --dport 111,515 -j DROP
	$IPT -A FORWARD -p dccp -i $intOut -o $intIn --dport 32768:32775 -j DROP
	$IPT -A FORWARD -p dccp -i $intOut -o $intIn --dport 137:139 -j DROP
	$IPT -A FORWARD -p dccp -i $intOut -o $intIn -m multiport --dport 111,515 -j DROP

#Block all SYN TO high ports
	$IPT -A FORWARD -p TCP --tcp-flags SYN SYN ! --dport 1:1024 -j DROP

#Block all TELNET
	$IPT -A FORWARD -p TCP --sport 23 -j DROP
	$IPT -A FORWARD -p TCP --dport 23 -j DROP
	$IPT -A FORWARD -p UDP --sport 23 -j DROP
	$IPT -A FORWARD -p UDP --dport 23 -j DROP

#Drop all packets destined for FIREWALL from the outside
	$IPT -A INPUT -i em1 -j DROP

#Accept Fragments (TESTING DOESNT WORK)
	$IPT -A FORWARD -f -j ACCEPT

#Accept ALL TCP Segments that belong to an existing connection
	$IPT -A FORWARD -p TCP -m state --state established -j DROP

#Custom SSH and FTP rules
$IPT -A PREROUTING -t mangle -p tcp --sport 22 \
  -j TOS --set-tos Minimize-Delay
$IPT -A PREROUTING -t mangle -p tcp --sport 21 \
  -j TOS --set-tos Minimize-Delay
$IPT -A PREROUTING -t mangle -p tcp --sport 20 \
  -j TOS --set-tos Maximize-Throughput

#Accept all inbound/outbound TCP on custom ports
	$IPT -A FORWARD -p TCP -m multiport --dport $TCPallow -j ACCEPT
	$IPT -A FORWARD -p TCP -m multiport --sport $TCPallow -j ACCEPT

#Accept all inbound/outbound UDP on custom ports
	$IPT -A FORWARD -p UDP -m multiport --dport $UDPallow -j ACCEPT
	$IPT -A FORWARD -p UDP -m multiport --sport $UDPallow -j ACCEPT

#Accept all ICMP on custom packet types
	$IPT -A FORWARD -p ICMP --icmp-type $ICMPallow -j ACCEPT









echo "New IPTABLES SET";


service iptables save
service iptables restart

iptables -L -v -x -n

