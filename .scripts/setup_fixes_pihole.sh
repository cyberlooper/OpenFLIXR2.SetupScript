#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

setup_fixes_pihole()
{
    info "Pi-hole fixes"
    info "- Changing default binary value"
    sed -i 's/binary="tbd"/binary="pihole-FTL-linux-x86_64"/' "/etc/.pihole/automated\ install/basic-install.sh"
    info "- Updating Pi-hole"
    pihole -up
    info "- Verifying versions"
    pihole -v
    info "- Putting the pi-hole install script back to how it should be"
    wget -O "/etc/.pihole/automated\ install/basic-install.sh" "https://install.pi-hole.net"
    info "- Done"
}