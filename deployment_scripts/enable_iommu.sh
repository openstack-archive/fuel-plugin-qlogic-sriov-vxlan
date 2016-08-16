#!/bin/bash

set -x
# Add entry in Grub
cp /etc/default/grub /etc/default/grub.orig	 
if ! grep -q 'GRUB_CMDLINE_LINUX_DEFAULT.*intel_iommu=on' /etc/default/grup; 
then 
	sed -ri '/^GRUB_CMDLINE_LINUX_DEFAULT\s*=/ s/^(.*)"$/\1 intel_iommu=on"/' /etc/default/grub 
fi
#update grub file
update-grub

#findout bnx2x driver package and install it.
debpk=`ls ./debpackage/bnx2x*`
dpkg -i $debpk

#update module.dep file
depmod -a

#update initramfs
update-initramfs -u -k all 
