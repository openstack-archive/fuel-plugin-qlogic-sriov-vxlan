#!/bin/bash

set -x
# Add entry in Grub
cp /etc/default/grub /etc/default/grub.orig	 
if ! grep -q 'GRUB_CMDLINE_LINUX_DEFAULT.*intel_iommu=on' /etc/default/grup; 
then 
	sed -ri '/^GRUB_CMDLINE_LINUX_DEFAULT\s*=/ s/^(.*)"$/\1 intel_iommu=on"/' /etc/default/grub 
fi
update-grub

