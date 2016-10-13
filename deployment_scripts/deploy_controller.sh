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
if [ $E3ENABLE == true ]; then
	vlan_enable=$VLAN_STATUS
	if [ $vlan_enable == true ]; then
		vlan_min_range=$VLAN_MIN_RANGE
		vlan_max_range=$VLAN_MAX_RANGE

		stanza="network_vlan_ranges"
		section="Qphysnet:$vlan_min_range:$vlan_max_range"
		insert_value_at_start $stanza $section /etc/neutron/plugins/ml2/ml2_conf.ini
	fi
fi 

if [ $E4ENABLE == true ]; then
	vlan_fastlinq_enable=$FASTLINQ_VLAN_STATUS
	if [ $vlan_fastlinq_enable == true ]; then
        	vlan_min_range=$FASTLINQ_VLAN_MIN_RANGE
        	vlan_max_range=$FASTLINQ_VLAN_MAX_RANGE

        	stanza="network_vlan_ranges"
        	section="Qphysnet_fastlinq:$vlan_min_range:$vlan_max_range"
        	insert_value_at_start $stanza $section /etc/neutron/plugins/ml2/ml2_conf.ini
	fi
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
	exit 1	
fi

# Make sure it add pci_vendor_devs correctly
if [ $E3ENABLE  == true ] && [ $E4ENABLE == false ];
then
	SUPPORTED_PCI_VENDOR_DEV="14e4:16ad"

elif [ $E4ENABLE == true ] && [ $E3ENABLE == false ];
then
	SUPPORTED_PCI_VENDOR_DEV="1077:1664"

elif [ $E4ENABLE == true ] && [ $E3ENABLE  == true ];
then	
	SUPPORTED_PCI_VENDOR_DEV="14e4:16ad,1077:1664"

else
	echo "No supported PCI Device"
	exit 1
fi


if ! grep -w "^supported_pci_vendor_devs.*" /etc/neutron/plugins/ml2/ml2_conf_sriov.ini
then
        sed -ri "0,/\[ml2_sriov\]+/s//\0\nsupported_pci_vendor_devs=$SUPPORTED_PCI_VENDOR_DEV/" /etc/neutron/plugins/ml2/ml2_conf_sriov.ini
else
        m=`grep -w "^supported_pci_vendor_devs.*" /etc/neutron/plugins/ml2/ml2_conf_sriov.ini | cut -d'=' -f2`
        if [ -n "$m" ]
        then
                sed -ri 's/(^\s*'supported_pci_vendor_devs'\s*=\s*)/\1'$SUPPORTED_PCI_VENDOR_DEV,'/g' /etc/neutron/plugins/ml2/ml2_conf_sriov.ini
        else
                sed -ri 's/(^\s*'supported_pci_vendor_devs'\s*=\s*)/\1'$SUPPORTED_PCI_VENDOR_DEV'/g' /etc/neutron/plugins/ml2/ml2_conf_sriov.ini
        fi
fi

## Enable PCIPassThroughFilter.
cp /etc/nova/nova.conf /etc/nova/nova.conf.org
stanza="scheduler_default_filters"
section="PciPassthroughFilter"
insert_value_at_start $stanza $section /etc/nova/nova.conf

service nova-scheduler restart
