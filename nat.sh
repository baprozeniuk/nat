#!/bin/bash 
#echo "Firewall is reloading!" | wall

###########################Variable Declairations###########################
WANINTERFACE=eth0
LANINTERFACE=tun0
LANINTERFACE2=0
LANINERFACE3=0
DMZINTERFACE=0
WANADDRESS=$(ifconfig $WANINTERFACE | grep "inet addr:" | awk -F ":" '{print $2}' | awk '{print $1}')
#WANADDRESS=192.249.57.76
#WANADDRESS=174.142.5.177
echo $WANADDRESS
###########################Flush Current Rules###########################
#backup counters before flushing
#/root/scripts/saveip.sh
iptables --flush
iptables -t nat --flush
iptables -t mangle --flush
iptables -P INPUT ACCEPT
iptables -P OUTPUT ACCEPT
iptables -F
#iptables -A INPUT -i $WANINTERFACE -j ACCEPT

###########################MAIN NAT SECTION###########################
sysctl -w net.ipv4.ip_forward=1 #enable fowarding
iptables -P FORWARD ACCEPT
iptables -F FORWARD 


echo "   FWD: Allow all connections OUT and only existing and related ones IN"
iptables -A FORWARD -i $WANINTERFACE -o $LANINTERFACE -m state --state ESTABLISHED,RELATED -j ACCEPT
#iptables -A FORWARD -i $WANINTERFACE -o $LANINTERFACE -j ACCEPT
iptables -A FORWARD -i $LANINTERFACE -o $WANINTERFACE -j ACCEPT

#iptables -A FORWARD -j LOG

echo "   Enabling SNAT (MASQUERADE) functionality on $WANINTERFACE"
# VERY IMPORTANT NOTE! --to-source MUST be set to your machine's IP address
iptables -t nat -A POSTROUTING -s 10.0.0.0/8 -o $WANINTERFACE -j SNAT --to-source $WANADDRESS
iptables -t nat -A POSTROUTING -s 192.168.0.0/16 -o $WANINTERFACE -j SNAT --to-source $WANADDRESS
iptables -I POSTROUTING -t nat -o $WANINTERFACE -d $WANADDRESS -j MASQUERADE

#echo "one to one NAT for VBox"
#iptables -t nat -I PREROUTING -i eth0 -d 174.142.5.182 -j DNAT --to-destination 192.168.24.2
#iptables -t nat -I POSTROUTING -o eth0 -s 192.168.24.2 -j SNAT --to-source 174.142.5.182
#iptables -t nat -I PREROUTING -d 174.142.5.182 -j DNAT --to-destination 192.168.24.2



###########################TRAFFIC COUNTING###########################
#Count All traffic for 
#iptables -I FORWARD -d 192.168.24.2 -j ACCEPT
#iptables -I FORWARD -s 192.168.24.2 -j ACCEPT


###########################DMZ NAT SECTION###########################

echo "   FWD: Allow all connections OUT and only existing and related ones IN"
iptables -A FORWARD -i $WANINTERFACE -o $DMZINTERFACE -m state --state ESTABLISHED,RELATED -j ACCEPT
#iptables -A FORWARD -i $WANINTERFACE -o $DMZINTERFACE -j ACCEPT
iptables -A FORWARD -i $DMZINTERFACE -o $WANINTERFACE -j ACCEPT

#iptables -A FORWARD -j LOG
#restore counters
#/root/scripts/restoreip.sh
###########################VPN PORT FORWARDING###########################
#Note there should be an incoming rule for the ports that are to be forwarded
echo "   Enabling Port fowarding rules"

#Example port forward 
#echo "port 59800 to 10.8.0.6 for bittorrent"
#iptables -t nat -I PREROUTING -p tcp --dport 59800 -j DNAT --to 10.8.0.6:59800
#iptables -I FORWARD -p tcp -d 10.8.0.6 --dport 59800 -j ACCEPT
#iptables -I FORWARD -p tcp -d 10.61.3.3 --dport 56000:56100 -j ACCEPT
#iptables -I FORWARD -p udp -d 10.61.3.3 --dport 56000:56100 -j ACCEPT
#iptables -t nat -A PREROUTING -p tcp --dport 56000:56100 -j DNAT --to-destination 10.61.3.3

#iptables -t nat -i ppp0 -I PREROUTING -p tcp --dport 443 -j DNAT --to 10.9.9.242:3389
#iptables -I FORWARD -p tcp -d 10.9.9.242 --dport 443 -j ACCEPT
#iptables -t nat -i eth0 -I PREROUTING -p tcp --dport 444 -j DNAT --to 10.60.0.1:444
#iptables -I FORWARD -p tcp -d 10.60.0.1 --dport 444 -j ACCEPT


##############################MISC SECURITY#########################
# IP Blocking
#block snmp from inet
iptables -I INPUT -i eth0 -p udp --dport 161 -j REJECT
#2003VM VBox VRDP
#iptables -I INPUT -i eth0 -p tcp --dport 3389 -j REJECT
#SMTP from internet
iptables -I INPUT -i eth0 -p tcp --dport 25 -j REJECT
#openvpn management interface
#iptables -I INPUT -i eth0 -p tcp --dport 3444 -j REJECT

#iptables -I INPUT -i eth0 -p tcp --dport 5900:5910 -j REJECT
#iptables -I INPUT -i eth0 -p tcp --dport 6001:6010 -j REJECT
