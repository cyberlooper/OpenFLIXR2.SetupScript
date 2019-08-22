#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

pihole_bypass()
{
    if [[ $(grep -c "127.0.0.1" "/etc/resolv.conf") -ge 1 ]]; then
        info "Bypassing pi-hole"
        sed -i "s#nameserver .*#nameserver 8.8.8.8#g" "/etc/resolv.conf"
        info "- Done"
    else
        info "Pi-hole already bypassed"
    fi
}
