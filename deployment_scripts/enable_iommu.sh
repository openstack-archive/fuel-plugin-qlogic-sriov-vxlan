#!/bin/bash

set -x
#set -ieux
# Add entry in Grub
cp /etc/default/grub /etc/default/grub.orig	 
#sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT="nomdmonddf nomdmonisw intel_iommu=on"/g' /etc/default/grub
# Comment : Line 7
#  add required parameters at the end of the cmdline
sed -i '/^GRUB_CMDLINE_LINUX_DEFAULT=/ s/$/" intel_iommu=on"/' /etc/default/grub
sed -i '/^GRUB_CMDLINE_LINUX_DEFAULT=/ s/""//' /etc/default/grub
update-grub

