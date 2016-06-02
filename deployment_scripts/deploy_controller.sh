#!/bin/bash
set -x
readonly DSDIR=$(dirname "$0")
source $DSDIR/common_function

## Enable SRIOV in neutron-server
cp /etc/neutron/plugins/ml2/ml2_conf.ini /etc/neutron/plugins/ml2/ml2_conf.ini.org
stanza="mechanism_drivers"
section="sriovnicswitch"
insert_value_at_start $stanza $section /etc/neutron/plugins/ml2/ml2_conf.ini

## Adding VLAN Support
# Check, if VLAN support is there or not.
vlan_enable=`get_values nic_vlan_support`
if [ $vlan_enable == true ]; then
	vlan_min_range=`get_values nic_10G_vlan_min_range`
	vlan_max_range=`get_values nic_10G_vlan_max_range`

	stanza="network_vlan_ranges"
	section="Qphysnet:$vlan_min_range:$vlan_max_range"
	insert_value_at_start $stanza $section /etc/neutron/plugins/ml2/ml2_conf.ini

fi

## SRIOV File Confiugartion
cp /etc/neutron/plugins/ml2/ml2_conf_sriov.ini /etc/neutron/plugins/ml2/ml2_conf_sriov.ini.org
if [ $MOS_VER == "7.0" ]
then
	sed -i "s/.*agent_required.*=.*/agent_required=false/g" /etc/neutron/plugins/ml2/ml2_conf_sriov.ini
elif [ $MOS_VER == "8.0" ]
then
	sed -i "s/.*agent_required.*=.*/agent_required=true/g" /etc/neutron/plugins/ml2/ml2_conf_sriov.ini
else
	echo "No support of MOS version"	
fi

# Make sure it add pci_vendor_devs correctly
if ! grep -w "^supported_pci_vendor_devs.*" /etc/neutron/plugins/ml2/ml2_conf_sriov.ini
then
        sed -ri "0,/\[ml2_sriov\]+/s//\0\nsupported_pci_vendor_devs=14e4:16ad/" /etc/neutron/plugins/ml2/ml2_conf_sriov.ini
else
        m=`grep -w "^supported_pci_vendor_devs.*" /etc/neutron/plugins/ml2/ml2_conf_sriov.ini | cut -d'=' -f2`
        if [ -n "$m" ]
        then
                sed -ri 's/(^\s*'supported_pci_vendor_devs'\s*=\s*)/\1'14e4:16ad,'/g' /etc/neutron/plugins/ml2/ml2_conf_sriov.ini
        else
                sed -ri 's/(^\s*'supported_pci_vendor_devs'\s*=\s*)/\1'14e4:16ad'/g' /etc/neutron/plugins/ml2/ml2_conf_sriov.ini
        fi
fi

## Enable PCIPassThroughFilter.
cp /etc/nova/nova.conf /etc/nova/nova.conf.org
stanza="scheduler_default_filters"
section="PciPassthroughFilter"
insert_value_at_start $stanza $section /etc/nova/nova.conf

service nova-scheduler restart

## ADD ml2_conf_sriov.ini file for Neutron Server
cp /etc/init/neutron-server.conf /etc/init/neutron-server.conf.org
sed -i s/'$CONF_ARG'/'$CONF_ARG --config-file \/etc\/neutron\/plugins\/ml2\/ml2_conf_sriov.ini'/g /etc/init/neutron-server.conf
# restarting neutron-server one time in script 
service neutron-server restart
