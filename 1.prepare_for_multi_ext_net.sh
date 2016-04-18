#!/bin/bash

L2_config_file=/etc/neutron/plugin.ini 
L3_config_file=/etc/neutron/l3_agent.ini 
DEFAULT_BR_EX="br-floating"
DEFAULT_PHYSNET="physnet-ex"

prepare_for_multi_ext_nets ()
{
	# 1.1 clear gateway_external_network_id and external_network_bridge parameters in /etc/neutron/l3_agent.ini
	if ! grep "^gateway_external_network_id" ${L3_config_file}; then
		sed -i "/^# gateway_external_network_id/a gateway_external_network_id =" ${L3_config_file}
	fi
	sed -i "/^external_network_bridge/c external_network_bridge =" ${L3_config_file}

	# 1.2 update configuration for the defualt current external network net04_ex
	grep "^bridge_mappings" /etc/neutron/plugins/ml2/ml2_conf.ini | grep ${DEFAULT_BR_EX}
	if (( 0 != $? )); then
		LINE=$(awk '/^bridge_mappings/ {print NR}' ${L2_config_file}) 
		sed -i "${LINE} s/$/,${DEFAULT_PHYSNET}:${DEFAULT_BR_EX}/" ${L2_config_file}
	else
		sed -i "/\[ovs\]/a bridge_mappings=${DEFAULT_PHYSNET}:${DEFAULT_BR_EX}" ${L2_config_file}
	fi

	# 1.3 update configuration of the current external network net04_ext in DB
	if mysql -e "show status;" &> /dev/null; then
		mysql neutron -e "update  ml2_network_segments set network_type='flat', physical_network='${DEFAULT_PHYSNET}' where network_type='local';"
	fi
}

prepare_for_multi_ext_nets
