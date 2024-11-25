#!/bin/bash

# Test if script has root privileges, exit otherwise
id=$(id -u)
if [ "${id}" -ne 0 ]; then
    echo "You need to run this with sudo or as root."
	exit 1
fi
# Define the lines to insert, using actual tab characters instead of \t
INSERT="	# Added by docker update\n	iptables -P FORWARD ACCEPT"

# File to edit
file="/var/packages/ContainerManager/scripts/start-stop-status"

# Search and check conditions
if ! grep -q 'iptables -P FORWARD ACCEPT' "${file}"; then
    match="^[[:space:]]*iptablestool --insmod"
    # Use sed to append the lines after the match
    sed -i "/${match}/a\\${INSERT}" "${file}"
    echo "Added missing IP forwarding configuration to ${file}"
	echo
	echo "To avoid a restart of docker, adding the rule now. This should automatically apply"
	echo "  with the next docker restart"
	iptables -P FORWARD ACCEPT
else
    echo "IP forwarding is already enabled in ${file}."
fi
