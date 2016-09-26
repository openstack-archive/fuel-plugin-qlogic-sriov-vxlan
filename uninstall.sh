FUEL_BOOTSTRAP_DIR="/var/www/nailgun/bootstraps/active_bootstrap/"
BACKUP_BOOTSTRAP_NUMBER_FILE="/tmp/bootstrap_backup"
BOOTSTRAP_CLI_YAML_FILE="/etc/fuel-bootstrap-cli/fuel_bootstrap_cli.yaml"
BACKUP_BOOTSTRAP_CLI_YAML_FILE="/etc/fuel-bootstrap-cli/fuel_bootstrap_cli.yaml.bkup"

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

	dockerctl shell cobbler cobbler sync > /dev/null 2>&1 
fi

