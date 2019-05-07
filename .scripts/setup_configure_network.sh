#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

setup_configure_network()
{
    local NETFILE
    NETFILE="/etc/network/interfaces"
    ## network
    info "Configuring network..."

    echo "# This file describes the network interfaces available on your system" > "${NETFILE}"
    echo "# and how to activate them. For more information, see interfaces(5)." >> "${NETFILE}"
    echo "source /etc/network/interfaces.d/*" >> "${NETFILE}"
    echo "" >> "${NETFILE}"
    echo "# The loopback network interface" >> "${NETFILE}"
    echo "auto lo" >> "${NETFILE}"
    echo "iface lo inet loopback" >> "${NETFILE}"
    echo "" >> "${NETFILE}"
    echo "# The primary network interface" >> "${NETFILE}"
    echo "auto eth0" >> "${NETFILE}"

    if [[ "${config[NETWORK]}" == "static" ]]; then
        info "Configuring network to use Static IP"

        echo "iface eth0 inet static" >> "${NETFILE}"
        echo "    address ${config[OPENFLIXR_IP]}" >> "${NETFILE}"
        if [[ ${config[OPENFLIXR_SUBNET]} != "" ]]; then
            echo "    netmask ${config[OPENFLIXR_SUBNET]}" >> "${NETFILE}"
        fi
        if [[ ${config[OPENFLIXR_GATEWAY]} != "" ]]; then
            echo "    gateway ${config[OPENFLIXR_GATEWAY]}" >> "${NETFILE}"
        fi
        echo "    dns-nameservers 127.0.0.1" >> "${NETFILE}"
        echo "" >> "${NETFILE}"

        info "Network configured using Static IP"
    else
        info "Configuring network to use DHCP"

        echo "iface eth0 inet dhcp" >> "${NETFILE}"
        echo "    dns-nameservers 127.0.0.1" >> "${NETFILE}"
        echo "" >> "${NETFILE}"

        info "Network configured using DHCP"
    fi
}