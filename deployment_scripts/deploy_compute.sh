#!/bin/bash
set -x
readonly DSDIR=$(dirname "$0")
source $DSDIR/common_function

count=0;
countf=0;

stor_nw_interface=`brctl show | grep br-storage  | xargs | cut -d' ' -f4`
mgmt_nw_interface=`brctl show | grep br-mgmt  | xargs | cut -d' ' -f4`

# Find out Qlogic/E3/E4 Adapter
ethx=`ls /sys/class/net/*/device/vendor`
for  interface_name in $ethx; do
	vendor=`cat $interface_name`
	if [ $vendor == "0x14e4" ]
	then
		qlogic_eth=`echo $interface_name | cut -f5 -d "/"`
		if [  -f /sys/class/net/$qlogic_eth/device/sriov_numvfs ]
		then
			 
			 if [ $qlogic_eth != $stor_nw_interface ] && [ $qlogic_eth != $mgmt_nw_interface ]
			 then
			 	ifconfig $qlogic_eth up
			 	q_eths[$count]=$qlogic_eth;
			 	count=$((count+1));
			 fi
		fi		
	fi

	if [ $vendor == "0x1077" ]
	then
		qlogic_fastlinq_eth=`echo $interface_name | cut -f5 -d "/"`
		if [  -f /sys/class/net/$qlogic_fastlinq_eth/device/sriov_numvfs ]
		then
			 
			 if [ $qlogic_fastlinq_eth != $stor_nw_interface ] && [ $qlogic_fastlinq_eth != $mgmt_nw_interface ]
			 then
			 	ifconfig $qlogic_fastlinq_eth up
			 	q_fastlinq_eths[$countf]=$qlogic_fastlinq_eth;
			 	countf=$((countf+1));
			 fi
		fi		
	fi
done

sleep 20;
#Find out Supported NIC with Link UP
count_eths_up=0
for i in "${q_eths[@]}" 
do
		port_state=`cat /sys/class/net/$i/operstate`
		if [ $port_state == "up" ]
		then
			q_eths_up[$count_eths_up]=$i;
			break;
			#count_eths_up=$((count_eths_up+1));
		fi
done

count_eths_up=0
for i in "${q_fastlinq_eths[@]}"
do
                port_state=`cat /sys/class/net/$i/operstate`
                if [ $port_state == "up" ]
                then
                        q_fastlinq_eths_up[$count_eths_up]=$i;
                        break;
                        #count_eths_up=$((count_eths_up+1));
                fi
done

echo "SR-IOV Supported Nic with Link up for 10G Adapter: ${q_eths_up[0]}"
echo "SR-IOV Supported Nic with Link up for FASTLINQ Adapter: ${q_fastlinq_eths_up[0]}"


# Enable VFs
if [ $E3ENABLE == true ]; then
	q_eth_len=${#q_eths_up[@]}
	n_10G_vfs=$E3VFS

	for (( count = 0; count < ${q_eth_len} ; count++ ));
	do
		sriov_totalvfs=`cat /sys/class/net/${q_eths_up[$count]}/device/sriov_totalvfs`
	
		if [ $sriov_totalvfs -gt $n_10G_vfs ]; then
 
			echo $n_10G_vfs > /sys/class/net/${q_eths_up[$count]}/device/sriov_numvfs
			cp /etc/rc.local /etc/rc.local.orig
			echo "ifconfig ${q_eths_up[$count]} up" >> /etc/rc.local
			echo "echo '$n_10G_vfs' > /sys/class/net/${q_eths_up[$count]}/device/sriov_numvfs" >> /etc/rc.local
		else
			echo $sriov_totalvfs > /sys/class/net/${q_eths_up[$count]}/device/sriov_numvfs
			cp /etc/rc.local /etc/rc.local.orig
			echo "ifconfig ${q_eths_up[$count]} up"  >> /etc/rc.local
			echo "echo '$sriov_totalvfs' > /sys/class/net/${q_eths_up[$count]}/device/sriov_numvfs" >> /etc/rc.local
		fi
	done
fi

if [ $E4ENABLE == true ]; then
	q_fastlinq_eth_len=${#q_fastlinq_eths_up[@]}
	n_fastlinq_vfs=$E4VFS
	for (( count = 0; count < ${q_fastlinq_eth_len} ; count++ ));
	do
        	sriov_totalvfs=`cat /sys/class/net/${q_fastlinq_eths_up[$count]}/device/sriov_totalvfs`

        	if [ $sriov_totalvfs -gt $n_fastlinq_vfs ]; then
                	echo $n_fastlinq_vfs > /sys/class/net/${q_fastlinq_eths_up[$count]}/device/sriov_numvfs
                	cp /etc/rc.local /etc/rc.local.orig
                	echo "ifconfig ${q_fastlinq_eths_up[$count]} up" >> /etc/rc.local
                	echo "echo '$n_fastlinq_vfs' > /sys/class/net/${q_fastlinq_eths_up[$count]}/device/sriov_numvfs" >> /etc/rc.local
        	else
                	echo $sriov_totalvfs > /sys/class/net/${q_fastlinq_eths_up[$count]}/device/sriov_numvfs
                	cp /etc/rc.local /etc/rc.local.orig
                	echo "ifconfig ${q_fastlinq_eths_up[$count]} up"  >> /etc/rc.local
                	echo "echo '$sriov_totalvfs' > /sys/class/net/${q_fastlinq_eths_up[$count]}/device/sriov_numvfs" >> /etc/rc.local
        	fi
	done
fi

# Add Entry in /etc/nova/nova.conf
cp /etc/nova/nova.conf /etc/nova/nova.conf.org

if [ $E3ENABLE == true ]; then
	for (( count = 0; count < ${q_eth_len} ; count++ ));
	do
		DEVNAME='"devname"'
		INTERFACE='"'${q_eths_up[$count]}'"'
		PNETWORK='"physical_network"'
		PNETWORK_NAME='"Qphysnet"'
	
		stanza="pci_passthrough_whitelist={$DEVNAME:$INTERFACE,$PNETWORK:$PNETWORK_NAME}"
		section="0,/\[DEFAULT\]"
		insert_value $stanza $section /etc/nova/nova.conf
	done
fi

if [ $E4ENABLE == true ]; then
	for (( count = 0; count < ${q_fastlinq_eth_len} ; count++ ));
	do
        	DEVNAME='"devname"'
        	INTERFACE='"'${q_fastlinq_eths_up[$count]}'"'
        	PNETWORK='"physical_network"'
        	PNETWORK_NAME='"Qphysnet_fastlinq"'

        	stanza="pci_passthrough_whitelist={$DEVNAME:$INTERFACE,$PNETWORK:$PNETWORK_NAME}"
        	section="0,/\[DEFAULT\]"
        	insert_value $stanza $section /etc/nova/nova.conf
	done
fi

if [ $MOS_VER == "8.0" ] 
then 
	
	#Add entry in libvirt-qemu for rw operations of /sys/device
        apprmd_file_location=/etc/apparmor.d/abstractions/libvirt-qemu

   	grep -wF "  /sys/devices/system/** r," $apprmd_file_location || sed -i /signal/i"\ \ /sys/devices/system/** r," $apprmd_file_location
        grep -wF "  /sys/bus/pci/devices/ r," $apprmd_file_location || sed -i /signal/i"\ \ /sys/bus/pci/devices/ r," $apprmd_file_location
        grep -wF "  /sys/bus/pci/devices/** r," $apprmd_file_location  || sed -i /signal/i"\ \ /sys/bus/pci/devices/** r," $apprmd_file_location
        grep -wF "  /sys/devices/pci*/** rw,"  $apprmd_file_location || sed -i /signal/i"\ \ /sys/devices/pci*/** rw," $apprmd_file_location
        grep -wF "  /{,var/}run/openvswitch/vhu* rw," $apprmd_file_location || sed -i /signal/i"\ \ /{,var/}run/openvswitch/vhu* rw," $apprmd_file_location


	apt-get install neutron-plugin-sriov-agent -y
	
	if [ $E3ENABLE == true ]; then
		# Add Physical Device Mappings in sriov_agent.ini
		for (( count = 0; count < ${q_eth_len} ; count++ ));
		do
			p_eths[$count]="Qphysnet:${q_eths_up[$count]}"
		done
		device_mapping_string=$(printf ",%s" "${p_eths[@]}")
		device_mapping_string=${device_mapping_string:1}
        fi

	if [ $E4ENABLE == true ]; then
		for (( count = 0; count < ${q_fastlinq_eth_len} ; count++ ));
        	do
                	p_eths[$count]="Qphysnet_fastlinq:${q_fastlinq_eths_up[$count]}"
        	done
        	device_mapping_string_fastlinq=$(printf ",%s" "${p_eths[@]}")
        	device_mapping_string_fastlinq=${device_mapping_string_fastlinq:1}
	fi

	cp /etc/neutron/plugins/ml2/sriov_agent.ini /etc/neutron/plugins/ml2/sriov_agent.ini.org

	if [ ! -z $device_mapping_string ] && [ -z $device_mapping_string_fastlinq ]; then
		DEVICE_MAPPING_STRING=$device_mapping_string
	elif [ -z $device_mapping_string ] && [ ! -z $device_mapping_string_fastlinq ]; then
		DEVICE_MAPPING_STRING=$device_mapping_string_fastlinq
	elif [ ! -z $device_mapping_string ] && [ ! -z $device_mapping_string_fastlinq ]; then
		DEVICE_MAPPING_STRING="$device_mapping_string,$device_mapping_string_fastlinq"
	else
		echo "No supported Interface"
		exit 1
	fi


	stanza="physical_device_mappings=$DEVICE_MAPPING_STRING"
	section="0,/\[sriov_nic\]"
	insert_value $stanza $section /etc/neutron/plugins/ml2/sriov_agent.ini

	stanza='[securitygroup]'
	grep -w '\[securitygroup\]' /etc/neutron/plugins/ml2/sriov_agent.ini || echo "$stanza" >> /etc/neutron/plugins/ml2/sriov_agent.ini

	stanza='firewall_driver=neutron.agent.firewall.NoopFirewallDriver'
	section="0,/\[securitygroup\]"
	insert_value $stanza $section /etc/neutron/plugins/ml2/sriov_agent.ini
	
	service neutron-plugin-sriov-agent restart
	
fi
service libvirtd restart
service nova-compute restart
