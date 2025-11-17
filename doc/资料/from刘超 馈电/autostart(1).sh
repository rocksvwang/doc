#/bin/sh
##set xtables-lib
export XTABLES_LIBDIR=/lib/aarch64-linux-gnu/xtables

#persistent storage log to outsieze device
#save log start process to file 
START_LOG_PATH="/tmp/start.log"

##get current path
CUR_PATH=$(find / -name 'autostart' )
#CUR_PATH=$(find /nvme -name 'autostart')

mkdir /nvme/nvme0n1p1/comm -p
ln -s /nvme/nvme0n1p1/comm  /comm
mkdir /nvme/nvme0n1p1/workspace -p
ln -s /nvme/nvme0n1p1/workspace  /workspace


###(2)set_and_start_bond
try_set_bond(){
	ip link delete bond0
	ip link add bond0 type bond mode active-backup miimon  100
  ip link set eth0 down
  ip link set eth1 down
  sleep 1
  ifconfig eth0 mtu 1400
  ifconfig eth1 mtu 1400
  ifconfig bond0 mtu 1400
	ip link set eth0 master bond0
	ip link set eth1 master bond0 
	
	BOND_IP="172.30.110.133"
	BOND_NETMASK="255.255.255.0"
	BOND_GATEWAY="172.30.110.254"
	ifconfig bond0 "$BOND_IP"  netmask "$BOND_NETMASK"  broadcast "$BOND_GATEWAY"
			
  ip link add link bond0 name bond0.1000 type vlan id 1000
  ip link add link bond0 name bond0.1001 type vlan id 1001

  ip -6 addr add fc00::5a36:0002/112       dev bond0.1001
  ip -6 addr add 2420:aaaa:203:5:6::2/112  dev bond0.1001
  
  ip link set bond0.1000 up
  ip link set bond0.1001 up
  ip link set bond0 up
  ip -6 route add fc00::5a1b:0/112 via 2420:aaaa:203:5:6::1 dev bond0.1001
}
sleep 1
try_set_bond &

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
  
###(3)set and start crond
try_set_and_start_crond(){
	if [[ -e "/etc/crontabs/root" ]];then
        	break
	else
        	cp  -p  $CUR_PATH/root  /etc/crontabs
	fi
	if [[ -e "/var/spool/cron/crontabs/root" ]];then
        	break
	else
	        cp  -p  $CUR_PATH/root /var/spool/cron/crontabs
	fi

	#start cron
	if [[ -e /usr/sbin/crond ]];then 
		/usr/sbin/crond    &
	fi	

}
try_set_and_start_crond &

###(4)set and start logrotate
try_set_and_start_logrotate(){
	if [[ -e  "/etc/logrotate.conf" ]];then
		break
	else
		cp -p $CUR_PATH/logrotate.conf /etc/
	fi
	#logrotate daily
	if [[ -e "/etc/cron.daily/logrotate" ]];then
		break
	else
		cp -p $CUR_PATH/logrotate   /etc/cron.daily/

	fi

	#logrotate hourly
	if [[ -e "/etc/cron.hourly/logrotate" ]];then
		break
	else
		cp -p $CUR_PATH/logrotate   /etc/cron.hourly/
	fi
}
#try_set_and_start_logrotate &

###(5)set and start rsyslog
try_set_and_start_rsyslog(){
	if [[ -e "/etc/rsyslog.d/50-default.conf" ]];then
        	break
	else
        	cp  -p $CUR_PATH/50-default.conf   /etc/rsyslog.d/
	fi
	if [[ -e "/etc/rsyslog.conf" ]];then
        	break
	else
        	cp  -p $CUR_PATH/rsyslog.conf      /etc/
	fi
	
	#set syslog logrotate 	
	if [[ -e "/etc/logrotate.d/rsyslog" ]];then
		break 
	else
		cp -p   $CUR_PATH/rsyslog   /etc/logrotate.d/
	fi
        
        #set xxapp logrotate
	#if [[ -e "/etc/logrotate.d/xxxx" ]];then
        #        break
        #else
        #        cp -p   $CUR_PATH/xxxx  /etc/logrotate.d/
        #fi
        	
	#start rsyslogd
	if [ -e /usr/sbin/rsyslogd ];then 
		/etc/init.d/rsyslog  start 
	fi 

}
try_set_and_start_rsyslog &


###(5)software set and start 

