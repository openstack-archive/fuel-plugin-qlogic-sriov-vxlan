FUEL_PLUGIN_DIR="/var/www/nailgun/plugins/fuel-plugin-qlogic-sriov*/"
ACTIVE_FUEL_BOOTSTRAP_DIR="/var/www/nailgun/bootstraps/active_bootstrap/"

if [ -d $ACTIVE_FUEL_BOOTSTRAP_DIR ]; then
  	
  # copy create_fastlinq_bootstrap shell script 
  cp $FUEL_PLUGIN_DIR/bootstraps_scripts/create_fastlinq_bootstrap /sbin
  	
  # copy reboot_fastlinq_bootstrap shell script 
  cp $FUEL_PLUGIN_DIR/bootstraps_scripts/reboot_fastlinq_bootstrap /sbin

fi
