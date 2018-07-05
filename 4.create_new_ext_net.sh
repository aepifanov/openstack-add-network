#!/bin/bash -x

create_new_ext_net ()
{
	NAME=${1:?"Please specify the name"}
	CIDR=${2:?"Please specify CIDR"}
	GATEWAY=${3:?"Please specify Gateway"}
	FIP_START=${4:?"Please specify Floating IP start of range"}
	FIP_END=${5:?"Please specify Floating IP end of range"}

	PHYSNET=physnet-${NAME}
	NAME=ext-${NAME}

	source openrc

	# check if it is exist and create net if not
	$(neutron net-list | awk -v NAME=${NAME} '{if (NAME == $4) exit 123;}')
	if (( 123 != $? )); then
		neutron net-create ${NAME} --provider:network_type flat --provider:physical_network ${PHYSNET} --router:external
	fi

	# check if it is exist and create subnet if not
	$(neutron subnet-list | awk -v NAME=$NAME '{if (NAME == $4) exit 123;}')
	if (( 123 != $? )); then
		neutron subnet-create ${NAME} ${CIDR} --name ${NAME} --gateway ${GATEWAY} --enable_dhcp=False --allocation-pool start=${FIP_START},end=${FIP_END}
	fi
}

create_new_ext_net $@
