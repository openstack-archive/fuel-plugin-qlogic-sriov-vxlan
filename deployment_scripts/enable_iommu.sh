#!/bin/bash

set -x
readonly DSDIR=$(dirname "$0")
source $DSDIR/common_function

# Add entry in Grub
cp /etc/default/grub /etc/default/grub.orig	 
if ! grep -q 'GRUB_CMDLINE_LINUX_DEFAULT.*intel_iommu=on' /etc/default/grup; 
then 
	sed -ri '/^GRUB_CMDLINE_LINUX_DEFAULT\s*=/ s/^(.*)"$/\1 intel_iommu=on"/' /etc/default/grub 
fi
#update grub file
update-grub

#findout bnx2x and qed/qede driver package and install it.
debpk=`ls ./debpackage/bnx2x*`
debpk_e4=`ls ./debpackage/fastlinq-dkms*`

if [ ! -z $debpk ] && [ $E3ENABLE == true ]; then
	dpkg -i $debpk 
fi

if [ ! -z $debpk_e4 ] && [ $E4ENABLE == true ]; then
	dpkg -i $debpk_e4
fi

#update module.dep file
depmod -a

#update initramfs
update-initramfs -u -k all 
