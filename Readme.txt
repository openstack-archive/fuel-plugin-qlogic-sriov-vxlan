Overview
--------
Configure Fuel Plugin with Scripts and Metadata to have SRIOV support with 
Qlogic NICs.

To Configure SRIOV 
-  Server Need to be enable with VT-d/SRIOV enable BIOS Settings.
-  Qlogic 3400/8400 series NIC Adapter Should support SRIOV, User can do "Ctrl+S" or QCScli/QCSGUI 
   OS based application to enable SRIOV on NIC Adapter.
-  Fuel-qlogic-sriov-plugin will create No. Vfs on the compute nodes as per user inputs for SR-IOV
   enabled NIC.

The SRIOV specification details how a single PCI Express (PCIe) device can be shared between
various guest operating systems—the VMs. Devices with SRIOV support multiple virtual functions
(VFs) on top of the physical function. VFs are enabled in hardware as a lightweight PCIe function that
can be directly assigned to a VM without hypervisor mediation. These VFs operate in the context of a
VM, and must be associated with a physical function (PF), a full-featured PCIe function that operates
in the context of the hypervisor or parent partition.

SRIOV provides direct VM connectivity and isolation across VMs. It allows the data to bypass the
software virtual switch (vSwitch) and provides near-native performance. The benefits to deploying
hardware-based SRIOV- enabled NICs include reduction of CPU and memory usage compared to
vSwitches. Moving the network virtualization into hardware (SRIOV adapters) relieves the
performance problems associated with vSwitches. By directing VM I/O directly to VFs and bypassing
the hypervisor, the vSwitches are no longer part of the data path. In addition, it significantly increases
the number of virtual networking functions for a single physical server.

Requirements
------------


| Requirement                    | Version                                             |
| ------------------------------ | ------------------------------------------------------------- |
| Mirantis OpenStack compatility | 7.0 or 8.0                                |

Qlogic 3400/8400 series 10Gbps NIC Adapter with supported switches and cables.


Limitations
-----------

- The Fuel plugin is only compatible with OpenStack environments deployed with Neutron
  using OVS + vlan.

- User can configure SRIOV on Single interface ( should not be Storage and Mgmt Nw) 
  whichever discover first with Link Up.

- QL NIC 3400/8400 Series Adapters are not able to set the quality of service (QoS) bandwidth 
  limit on SR-IOV VFs.

- The SRIOV IP Network interface does not receive the DHCP IP address while creating the VM.
  Therefore, you must assign the IP address for the SRIOV interface manually.

Installation
------------

To install Qlogic plugin, follow these steps:

1. Install Fuel Master node. For more information on how to create a Fuel Master node, please see

[Mirantis Fuel 8.0 documentation](https://docs.mirantis.com/openstack/fuel/fuel-8.0/)
[Mirantis Fuel 7.0 documentation](https://docs.mirantis.com/openstack/fuel/fuel-7.0/)


2. Download fuel plugin qlogic sriov code. 

	https://review.openstack.org/#/q/project:openstack/fuel-plugin-qlogic-sriov-vxlan 
	cd fuel-plugin-qlogic-sriov
	pip install fuel-plugin-builder
    	fpb --build .

	It will generate fuel-plugin-qlogic-sriov-1.0-<package_version>-1.noarch.rpm	

3. Copy the plugin on Fuel Master node.

	# scp fuel-plugin-qlogic-sriov-1.0-<package_version>-1.noarch.rpm  master_node@:/root/

4. Install the plugin:
	
     	# cd /root
     	# fuel plugins --install fuel-plugin-qlogic-sriov-1.0-<package_version>-1.noarch.rpm


5. Verify the plugin installed successfully using below command:

	# fuel plugins

	id | name                     | version | package_version
	---|--------------------------|---------|----------------
	17 | fuel-plugin-qlogic-sriov | 1.0.0   | 3.0.0


Plugin-Configuration
--------------------
Once Fuel plugin qlogic sriov gets installed , below configuration needs to be done in settings tab

 - For MoS 7.0, go to settings tab -> Qlogic openstack Fuel plugin for SRIOV Configuration
 - For MOS 8.0, go to settings tab -> Other, under "Qlogic openstack Fuel plugin for SRIOV Configuration"
 - Enable SR-IOV for Qlogic NX2 10G Ethernet
 - Give No of Vfs.
 - Enable VLAN for SRIOV VF with Start and End Range. ( Make sure this VLAN range should be supported @ switch 
   level conncted ports)
 - it will create SRIOV VFs on Qlogic 3400/8400 adpater single interface, whichever discover first.

Usage
-----

We need to use CLI to create INstance with SRIOV ports.

 - Go to Controller Node.

 - Create SRIOV Nw with flat or VLAN configuration as per settings in Fuel plugin

	neutron net-create --provider:physical_network=Qphysnet --provider:network_type=flat sriov

	neutron subnet-create sriov 10.0.0.0/24 --name sriov-subnet --dns-nameserver 8.8.4.4 --gateway 10.0.0.1

 - Create SRIOV port with binding as vnic_type:direct

	neutron port-create <sriov nw net id> --name P1 --binding:vnic_type direct


 - Create VM with SRIOV port

	nova boot --flavor m1.medium --image <image_id> --nic port-id=<P1 id> VM1
