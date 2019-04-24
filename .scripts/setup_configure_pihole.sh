#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

setup_configure_pihole()
{
    info "Updating PiHole settings"
    if [[ "${config[NETWORK]}" == "static" ]]; then
        sed -i 's/IPV4_ADDRESS.*/IPV4_ADDRESS='${config[OPENFLIXR_IP]}'/' /etc/pihole/setupVars.conf
        service pihole-FTL restart >> $LOG_FILE 2>&1
        pihole -g -sd >> $LOG_FILE 2>&1
    else
        ip=$(/sbin/ip -o -4 addr list eth0 | awk '{print $4}' | cut -d/ -f1)
        sed -i 's/IPV4_ADDRESS.*/IPV4_ADDRESS=/' /etc/pihole/setupVars.conf
        service pihole-FTL restart >> $LOG_FILE 2>&1
        pihole -g -sd >> $LOG_FILE 2>&1
    fi

}
