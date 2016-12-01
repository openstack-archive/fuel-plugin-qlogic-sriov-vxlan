#!/bin/bash
FUEL_BOOTSTRAP_DIR="/var/www/nailgun/bootstraps/active_bootstrap/"
BACKUP_BOOTSTRAP_NUMBER_FILE="/var/fastlinq_backup/bootstrap_backup"
BOOTSTRAP_CLI_YAML_FILE="/etc/fuel-bootstrap-cli/fuel_bootstrap_cli.yaml"
BACKUP_BOOTSTRAP_CLI_YAML_FILE="/etc/fuel-bootstrap-cli/fuel_bootstrap_cli.yaml.bkup"
TEMP_INITRDDIR="/var/initrd-orig/"
FUEL_VERSION=`cat /etc/fuel_release`
# Verify run is over Fuel Master and we are not During upgrade
if [ -d $FUEL_BOOTSTRAP_DIR ]; then
	
	if [ -f $BACKUP_BOOTSTRAP_NUMBER_FILE ]; then
    	active_bootstrap_number=`cat $BACKUP_BOOTSTRAP_NUMBER_FILE`
    
    		if [ ! -z $active_bootstrap_number ]; then
    			fuel-bootstrap activate $active_bootstrap_number > /dev/null 2>&1 
    			rm $BACKUP_BOOTSTRAP_NUMBER_FILE
    		fi
  	fi
	
	fastlinq_activated=`fuel-bootstrap list | grep fastlinq_bootstrap | cut -d "|" -f2`
	if [ ! -z $fastlinq_activated ]; then
		fuel-bootstrap delete $fastlinq_activated > /dev/null 2>&1
	fi
	
  	if [ -f $BACKUP_BOOTSTRAP_CLI_YAML_FILE ]; then
    		mv $BACKUP_BOOTSTRAP_CLI_YAML_FILE $BOOTSTRAP_CLI_YAML_FILE
  	fi

	rm /sbin/create_fastlinq_bootstrap /sbin/reboot_fastlinq_bootstrap

	if [ -d $TEMP_INITRDDIR ]; then
		rm -rf $TEMP_INITRDDIR
	fi

	if [ "$FUEL_VERSION" == "8.0" ];
	then
        	dockerctl shell cobbler cobbler sync > /dev/null 2>&1
	fi

	if [ "$FUEL_VERSION" == "9.0" ];
	then
        	cobbler sync > /dev/null 2>&1
	fi

fi

