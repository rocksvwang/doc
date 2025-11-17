
#!/bin/sh
##get current path
CUR_PATH=$(find / -name 'autostart')
#mkdir /nvme/nvme1n1p1/
#mount /dev/nvme1n1p1 /nvme/nvme1n1p1/
##set an start network


  INAME1="eth2"
  # for static network
  STATIC_IP1="192.168.2.133"
  STATIC_NETMASK1="255.255.255.0"
  STATIC_GATEWAY1="192.168.2.1"

  ifconfig $INAME1 down
  ifconfig $INAME1 arp
  ifconfig $INAME1 "$STATIC_IP1" netmask "$STATIC_NETMASK1"
  route add default gw "$STATIC_GATEWAY1"
  ifconfig $INAME1 up


  ifconfig lo 127.0.0.1 netmask 255.0.0.0
  ifconfig lo up
        
        
###(2)set_and_start_bond
try_set_bond(){
	ip link delete bond0
	#set bond interface 
	ip link add bond0 type bond mode active-backup miimon  100

	#set members interface 
	ip link set eth0 master bond0
	ip link set eth1 master bond0 
			
	#set bond ip	
	BOND_IP="172.30.110.133"
	BOND_NETMASK="255.255.255.0"
	BOND_GATEWAY="172.30.110.254"
        BOND_IPV6INIT=yes
        BOND_IPV6_AUTOCONF=no
        BOND_IPV6_FAILURE=no
        BOND_IPV6ADDR="fc00::5a36:0002/112"

       
	ifconfig bond0 "$BOND_IP"  netmask "$BOND_NETMASK"  broadcast "$BOND_GATEWAY"
#	ifconfig bond0 add fc00::5a36:0002/112

ip link add link bond0 name bond0.1000 type vlan id 1000
ip link add link bond0 name bond0.1001 type vlan id 1001

ip -6 addr add fc00::5a36:0002/112  dev bond0.1001
ip -6 addr add 2420:aaaa:203:5:6::2/112  dev bond0.1001
ip -6 route add fc00::5a1b:0/112 via 2420:aaaa:203:5:6::1 dev bond0.1001
ip link set bond0.1001 up
ip link set bond0.1000 up
ip link set bond0 up
}
sleep 1
#使用静态ip时注释掉bond配置函数!!!
try_set_bond &

###(3)set and start crond
try_set_and_start_crond(){
	if [[ -f "/etc/crontabs/root" ]];then
        	break
	else
        	cp  -p  $CUR_PATH/root  /etc/crontabs
	fi
	if [[ -f "/var/spool/cron/crontabs/root" ]];then
        	break
	else
	        cp  -p  $CUR_PATH/root /var/spool/cron/crontabs
	fi

#start crond
#crond &
}
try_set_and_start_crond &


###(4)set and start rsyslog
try_set_and_start_rsyslog(){
	if [[ -f "/etc/rsyslog.d/50-default.conf" ]];then
        	break
	else
        	cp  -p $CUR_PATH/50-default.conf   /etc/rsyslog.d/
	fi
	if [[ -f "/etc/rsyslog.conf" ]];then
        	break
	else
        	cp  -p $CUR_PATH/rsyslog.conf      /etc/
	fi

	#start rsyslogd
	#rsyslogd -n -iNOME &

}
try_set_and_start_rsyslog &


###(5)software set and start 

try_set_network(){
	INAME="eth0"
	# for static network
	STATIC_IP="192.168.0.133"
	STATIC_NETMASK="255.255.255.0"
	STATIC_GATEWAY="192.168.0.1"

	ifconfig $INAME down
	ifconfig $INAME arp
	ifconfig $INAME "$STATIC_IP" netmask "$STATIC_NETMASK"
	route add default gw "$STATIC_GATEWAY"
	ifconfig $INAME up
        
	#for dhcp 
	#dhclient

	#for loop device 
	ifconfig lo up


	INAME1="eth1"
	# for static network
        STATIC_IP1="192.168.1.133"
        STATIC_NETMASK1="255.255.255.0"
        STATIC_GATEWAY1="192.168.1.1"

        ifconfig $INAME1 down
        ifconfig $INAME1 arp
        ifconfig $INAME1 "$STATIC_IP1" netmask "$STATIC_NETMASK1"
        route add default gw "$STATIC_GATEWAY1"
        ifconfig $INAME1 up

        #for dhcp
        #dhclient

#        #for loop device
#        ifconfig lo up
#        
#	INAME1="eth2"
#	# for static network
#        STATIC_IP1="192.168.2.133"
#        STATIC_NETMASK1="255.255.255.0"
#        STATIC_GATEWAY1="192.168.2.1"
#
#        ifconfig $INAME1 down
#        ifconfig $INAME1 arp
#        ifconfig $INAME1 "$STATIC_IP1" netmask "$STATIC_NETMASK1"
#        route add default gw "$STATIC_GATEWAY1"
#        ifconfig $INAME1 up
#
#        #for dhcp
#        #dhclient
#
#        #for loop device
}
sleep 1
####使用bond的时候注释掉静态ip配置函数!!!
##try_set_network &

/bin/bash /nvme/nvme0n1p1/workspace/01/0001/sfc/scripts/sfcInit_tft.sh &
sleep 20
/bin/bash /nvme/nvme0n1p1/comm/common.sh 01H A205H XW SFC 1 07H &
