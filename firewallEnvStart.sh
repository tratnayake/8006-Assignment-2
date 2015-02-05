#! /bin/bash
SUBNET_ADDR='192.168.10.0/24'

# ***************************
#    POSTROUTING
# ***************************

#Mask all outgoing as 192.168.0.14
iptables -t nat -A POSTROUTING -s $SUBNET_ADDR -o em1 -j SNAT --to-source 192.168.0.14

# ***************************
#     PREROUTING
# ***************************

#Direct all incoming packets to 192.168.10.2
iptables -t nat -A PREROUTING -i em1 -j DNAT --to-destination 192.168.10.2
