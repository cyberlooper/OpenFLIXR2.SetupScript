#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

setup_configure_pihole()
{
    local PIHOLE_DNS_3
    info "Updating PiHole settings"
    if [[ "${config[NETWORK]}" == "static" ]]; then
        PIHOLE_DNS_3=${config[OPENFLIXR_GATEWAY]}
    else
        PIHOLE_DNS_3=${ROUTER_IP}
    fi
    if [[ $(grep -c "PIHOLE_DNS_3" "/etc/pihole/setupVars.conf") == 0 ]]; then
        info "- Adding Pi-hole DNS 'Custom 1'"
        echo "PIHOLE_DNS_3=${PIHOLE_DNS_3}" >> "/etc/pihole/setupVars.conf"
    else
        info "- Updating Pi-hole DNS 'Custom 1'"
        sed -i 's/PIHOLE_DNS_3.*/PIHOLE_DNS_3='${PIHOLE_DNS_3}'/' /etc/pihole/setupVars.conf
    fi
    info "- Setting Pi-hole IPV4_ADDRESS"
    sed -i 's/IPV4_ADDRESS.*/IPV4_ADDRESS='${config[OPENFLIXR_IP]}'/' /etc/pihole/setupVars.conf
    info "- Restarting Pi-hole"
    service pihole-FTL restart >> $LOG_FILE 2>&1
    pihole -g -sd >> $LOG_FILE 2>&1
}
