#!/bin/bash

set -eux


## Enable SRIOV in neutron-server
cp /etc/neutron/plugins/ml2/ml2_conf.ini /etc/neutron/plugins/ml2/ml2_conf.ini.org
grep -q "mechanism_drivers.*=.*openvswitch,sriovnicswitch.*" /etc/neutron/plugins/ml2/ml2_conf.ini || sed -i "s/mechanism_drivers =openvswitch/mechanism_drivers =openvswitch,sriovnicswitch/g" /etc/neutron/plugins/ml2/ml2_conf.ini

## SRIOV File Confiugartion
cp /etc/neutron/plugins/ml2/ml2_conf_sriov.ini /etc/neutron/plugins/ml2/ml2_conf_sriov.ini.org
sed -i "s/.*agent_required*=.*/agent_required=false/g" /etc/neutron/plugins/ml2/ml2_conf_sriov.ini
sed -i "s/# supported_pci_vendor_devs.*=.*/supported_pci_vendor_devs = 14e4:16ad, 14e4:16a1/g" /etc/neutron/plugins/ml2/ml2_conf_sriov.ini
service neutron-server restart

## Enable PCIPassThroughFilter.
cp /etc/nova/nova.conf /etc/nova/nova.conf.org
current_enable_filter=`grep "^scheduler_default_filters" /etc/nova/nova.conf | cut -f2 -d "=" | sed 's/"PciPassthroughFilter//g'`
grep -w  "^scheduler_default_filters.*=.*PciPassthroughFilter.*" /etc/nova/nova.conf || sed -i s/^scheduler_default_filters=.*/scheduler_default_filters="$current_enable_filter,PciPassthroughFilter"/g /etc/nova/nova.conf

grep -q -F 'scheduler_available_filters=nova.scheduler.filters.pci_passthrough_filter.PciPassthroughFilter' /etc/nova/nova.conf || \
    sed -i '/scheduler_available_filters/a scheduler_available_filters=nova.scheduler.filters.pci_passthrough_filter.PciPassthroughFilter' /etc/nova/nova.conf
service nova-scheduler restart

## ADD ml2_conf_sriov.ini file for Neutron Server
cp /etc/init/neutron-server.conf /etc/init/neutron-server.conf.org
sed -i s/'$CONF_ARG'/'$CONF_ARG --config-file \/etc\/neutron\/plugins\/ml2\/ml2_conf_sriov.ini'/g /etc/init/neutron-server.conf
service neutron-server restart
