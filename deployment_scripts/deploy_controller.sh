#!/bin/bash

set -eux


## Enable SRIOV in neutron-server
# Comment : Line 8
# Fixing openvswitch driver addition in ml2_conf.ini to make it more generalize 
cp /etc/neutron/plugins/ml2/ml2_conf.ini /etc/neutron/plugins/ml2/ml2_conf.ini.org
grep -q '^\s*mechanism_drivers\s*=.*sriovnicswitch' /etc/neutron/plugins/ml2/ml2_conf.ini || sed -ri 's/(^\s*mechanism_drivers\s*=\s*)/\1sriovnicswitch,/g' /etc/neutron/plugins/ml2/ml2_conf.ini

## SRIOV File Confiugartion
# Comment : Line 12
# Fixing missed dot after "d" here "agent_required*="
cp /etc/neutron/plugins/ml2/ml2_conf_sriov.ini /etc/neutron/plugins/ml2/ml2_conf_sriov.ini.org
sed -i "s/.*agent_required.*=.*/agent_required=false/g" /etc/neutron/plugins/ml2/ml2_conf_sriov.ini

# Comment : Line 13
# Make sure it add pci_vendor_devs correctly
grep -w '^supported_pci_vendor_devs.*=.*14e4:16ad,.*14e4:16a1' /etc/neutron/plugins/ml2/ml2_conf_sriov.ini || sed -i "/\[ml2_sriov\]/asupported_pci_vendor_devs = 14e4:16ad, 14e4:16a1" /etc/neutron/plugins/ml2/ml2_conf_sriov.ini

## Enable PCIPassThroughFilter.
cp /etc/nova/nova.conf /etc/nova/nova.conf.org
current_enable_filter=`grep "^scheduler_default_filters" /etc/nova/nova.conf | cut -f2 -d "=" | sed 's/"PciPassthroughFilter//g'`
grep -w  "^scheduler_default_filters.*=.*PciPassthroughFilter.*" /etc/nova/nova.conf || sed -i s/^scheduler_default_filters=.*/scheduler_default_filters="$current_enable_filter,PciPassthroughFilter"/g /etc/nova/nova.conf

service nova-scheduler restart

## ADD ml2_conf_sriov.ini file for Neutron Server
cp /etc/init/neutron-server.conf /etc/init/neutron-server.conf.org
sed -i s/'$CONF_ARG'/'$CONF_ARG --config-file \/etc\/neutron\/plugins\/ml2\/ml2_conf_sriov.ini'/g /etc/init/neutron-server.conf
# Comment : Line 14
# restarting neutron-server one time in script 
service neutron-server restart
