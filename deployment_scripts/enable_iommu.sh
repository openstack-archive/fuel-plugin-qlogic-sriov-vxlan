#!/bin/bash

set -x
#set -ieux
# Add entry in Grub
cp /etc/default/grub /etc/default/grub.orig	 
sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT="nomdmonddf nomdmonisw intel_iommu=on"/g' /etc/default/grub
update-grub

