..
 This work is licensed under the Apache License, Version 2.0.

 http://www.apache.org/licenses/LICENSE-2.0

=============================
Qlogic Fuel plugin
=============================

Qlogic Fuel Plugin 1.0.0 supports SRIOV for QLogic 3400/8400 series NIC Adapters
for Fuel 7.0 and Fuel 8.0


Problem description
===================

Fuel to supports Qlogic 3400/8400 series NIC Adapter SRIOV using Fuel Qlogic SRIOV 
plugin

Proposed change
===============

Implement a Fuel plugin that will install and configure Qlogic 3400/8400 series NIC 
Adapter SRIOV support. 

Alternatives
------------

User can do this configuration manually, but it requires lot of attention while changing 
different configuration file and which is risk for deployed cloud enviornment.

Data model impact
-----------------

None

REST API impact
---------------

None

Upgrade impact
--------------

None

Security impact
---------------

None

Notifications impact
--------------------

None

Other end user impact
---------------------

None

Performance Impact
------------------

Using Qlogic 3400/8400 Series Adapter with Mirantis openstack will 
support comprehensive list of virtulization and multitenat services
including SRIOV and will incerese cloud performnace significantly.

Other deployer impact
---------------------

None

Developer impact
----------------

None

Implementation
==============

The Fuel plugin Qlogic SRIOV is having scripts and Metadata to have 
SRIOV support with Qlogic 3400/8400 series NICs. 

This Plugin will do:

* Will enable SRIOV support on Qlogic 3400/8400 series NIC on Compute Nodes.
* Update the No. of SRIOV VFs for Qlogic NIC.
* IT will support VLAN for SRIOV VFs with start and end Range.

Assignee(s)
-----------
Rick Hicksted <rick.hicksted@qlogic.com>
Jigar Shah <jigar.shah@qlogic.com>
Shalaka Kulkarni <shalaka.kulkarni@qlogic.com>

Work Items
----------

* Implement the Fuel plugin.
* Implement the shell script for deployment 
* Testing (CI verification and manual tests).
* Write the documentation.

Dependencies
============

* Fuel 7.0 and Fuel 8.0

Testing
=======

* Prepare a test plan.
* Test the plugin by deploying environments with all relevant Fuel deployment
  modes.

Documentation Impact
====================

* Plugin Guide (how to install the plugin, and configure the plugin, 
  which features the plugin provides, how to use them in the 
  deployed OpenStack environment).
* Test Plan.
* Test Report.

References
==========
NA
