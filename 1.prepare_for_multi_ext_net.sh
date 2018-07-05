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
	if ! grep -q "^bridge_mappings" ${L2_config_file}; then
		# if there are no bridge_mappings in l2_config_file, add one
		sed -i "/\[ovs\]/a bridge_mappings=${DEFAULT_PHYSNET}:${DEFAULT_BR_EX}" ${L2_config_file}
	elif ! grep "^bridge_mappings" ${L2_config_file} | grep -q ${DEFAULT_BR_EX}; then
		# if there are bridge_mappings, but default_br_ex isn't mapped, append its mapping
		sed -i "/^bridge_mappings/s/$/,${DEFAULT_PHYSNET}:${DEFAULT_BR_EX}/" ${L2_config_file}
	else
		# else, if there is a mapping for default_br_ex, do nothing
		:
	fi

	# 1.3 update configuration of the current external network net04_ext in DB
	if mysql -e "show status;" &> /dev/null; then
		mysql neutron -e "update  ml2_network_segments set network_type='flat', physical_network='${DEFAULT_PHYSNET}' where network_type='local';"
	fi
}

prepare_for_multi_ext_nets
