#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

setup_configure_network()
{
    ## network
    info "Configuring network..."

    if [[ "${config[NETWORK]}" == "static" ]]; then
        cat > /etc/network/interfaces<<EOF
# This file describes the network interfaces available on your system
# and how to activate them. For more information, see interfaces(5).
source /etc/network/interfaces.d/*
# The loopback network interface
auto lo eth0
iface lo inet loopback
# The primary network interface
iface eth0 inet static
address ${config[OPENFLIXR_IP]}
netmask ${config[OPENFLIXR_SUBNET]}
gateway ${config[OPENFLIXR_GATEWAY]}
dns-nameservers 127.0.0.1
EOF
    else
        cat > /etc/network/interfaces<<EOF
# This file describes the network interfaces available on your system
# and how to activate them. For more information, see interfaces(5).
source /etc/network/interfaces.d/*
# The loopback network interface
auto lo eth0
iface lo inet loopback
# The primary network interface
iface eth0 inet dhcp
dns-nameservers 127.0.0.1
EOF
    fi
}