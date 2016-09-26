#!/bin/bash
interface_name=`ls /sys/class/net/`
for interface in $interface_name
do
	ethtool -i $interface | grep qed
	if [ $? -eq 0 ]; then
		ifconfig $interface up
	fi
done
