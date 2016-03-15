#!/bin/bash
# In case of MOS maintenance udpate is applied, User needsto run this script
# manually to mkae sure ml2_sriov_agent.ini file is added a part of 
# neutron_server.conf file and then restart neutron-server service

## ADD ml2_conf_sriov.ini file for Neutron Server
cp /etc/init/neutron-server.conf /etc/init/neutron-server.conf.org
sed -i s/'$CONF_ARG'/'$CONF_ARG --config-file \/etc\/neutron\/plugins\/ml2\/ml2_conf_sriov.ini'/g /etc/init/neutron-server.conf
# restarting neutron-server one time in script
service neutron-server restart

