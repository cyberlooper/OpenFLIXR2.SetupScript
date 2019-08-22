#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

pihole_unbypass()
{
    if [[ $(grep -c "127.0.0.1" "/etc/resolv.conf") -eq 0 ]]; then
        info "Undo bypassing pi-hole"
        sed -i "s#nameserver .*#nameserver 127.0.0.1#g" "/etc/resolv.conf"
        info "- Done"
    else
        info "Pi-hole isn't bypassed. Nothing to undo!"
    fi
}
