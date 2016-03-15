#!/bin/bash

set -x
#set -ieux
count=0;
#num_vfs=8;
#echo "Compute node" > /tmp/compute-sriov.txt

# Find out Qlogic/E3 Adapter.
ethx=`ls /sys/class/net/eth*/device/vendor`
for  interface_name in $ethx; do
	vendor=`cat $interface_name`
	if [ $vendor == "0x14e4" ]
	then
		qlogic_eth=`echo $interface_name | cut -f5 -d "/"`
		if [  -f /sys/class/net/$qlogic_eth/device/sriov_numvfs ]
		then
			 q_eths[$count]=$qlogic_eth;
			 count=$((count+1));
		fi		
	fi
done

#Find out Supported NIC with Link UP
count_eths_up=0
for i in "${q_eths[@]}" 
do
		port_state=`cat /sys/class/net/$i/operstate`
		if [ $port_state == "up" ]
		then
			q_eths_up[$count_eths_up]=$i;
			count_eths_up=$((count_eths_up+1));
		fi
done
echo "SR-IOV Supported Nic with Link up: ${q_eths_up[0]}"

# Add entry in Grub
#cp /etc/default/grub /etc/default/grub.orig	 
#sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT="nomdmonddf nomdmonisw intel_iommu=on"/g' /etc/default/grub
#update-grub

# Enable VFs
q_eth_len=${#q_eths_up[@]}

n_10G_vfs=`ruby -r hiera -r yaml -e "hiera = Hiera.new(:config => '/etc/puppet/hiera.yaml'); qlogic = hiera.lookup 'fuel-plugin-qlogic-sriov', [], {};  puts qlogic['"num_10G_vfs"']"`

for (( count = 0; count < ${q_eth_len} ; count++ ));
do 
	echo $n_10G_vfs > /sys/class/net/${q_eths_up[$count]}/device/sriov_numvfs
	cp /etc/rc.local /etc/rc.local.orig
	echo "echo '$n_10G_vfs' > /sys/class/net/${q_eths_up[$count]}/device/sriov_numvfs" >> /etc/rc.local
done


# Add Entry in /etc/nova/nova.conf
cp /etc/nova/nova.conf /etc/nova/nova.conf.org

for (( count = 0; count < ${q_eth_len} ; count++ ));
do
	grep -w '^pci_passthrough_whitelist={"devname":"'${q_eths_up[$count]}'","physical_network":"Qphysnet"}' /etc/nova/nova.conf ||  sed '0,/\[DEFAULT\]/ a pci_passthrough_whitelist={"devname":"'${q_eths_up[$count]}'","physical_network":"Qphysnet"}' /etc/nova/nova.conf >  /etc/nova/nova_q.conf
	cp /etc/nova/nova_q.conf /etc/nova/nova.conf 
done


# Add Entry Regarding Security group with NO Firewall Driver.
cp /etc/neutron/plugins/ml2/ml2_conf.ini /etc/neutron/plugins/ml2/ml2_conf.ini.org
grep -w '^firewall_driver = neutron.agent.firewall.NoopFirewallDriver' /etc/neutron/plugins/ml2/ml2_conf.ini || sed '/\[securitygroup\]/ a firewall_driver = neutron.agent.firewall.NoopFirewallDriver' /etc/neutron/plugins/ml2/ml2_conf.ini > /etc/neutron/plugins/ml2/ml2_conf_q.ini
cp -r /etc/neutron/plugins/ml2/ml2_conf_q.ini /etc/neutron/plugins/ml2/ml2_conf.ini


# Add Physical Device Mappings.
m1="" 
for (( count = 0; count < ${q_eth_len} ; count++ ));
do
	p_eths[$count]="Qphysnet:${q_eths_up[$count]}"
done
device_mapping_string=$(printf ",%s" "${p_eths[@]}")
device_mapping_string=${device_mapping_string:1}
echo $device_mapping_string
grep -w '^physical_device_mappings='${device_mapping_string}'' /etc/neutron/plugins/ml2/ml2_conf_sriov.ini || awk '{ print } !flag && /\[sriov_nic\]/ { print "physical_device_mappings='${device_mapping_string}'"; flag =1 }' /etc/neutron/plugins/ml2/ml2_conf_sriov.ini  > /etc/neutron/plugins/ml2/ml2_conf_sriov_q.ini
cp /etc/neutron/plugins/ml2/ml2_conf_sriov_q.ini /etc/neutron/plugins/ml2/ml2_conf_sriov.ini
