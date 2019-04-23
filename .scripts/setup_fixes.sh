#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

setup_fixes()
{
    info "Various fixes not handled anywhere else in setup"
    info "  Sonarr apt repo fix"
    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 0xA236C58F409091A18ACA53CBEBFF6B99D9B78493 > /dev/null
    if [[ -f "/etc/apt/sources.list.d/sonarr.list" ]]; then
        rm /etc/apt/sources.list.d/sonarr.list
    fi
    echo "deb http://apt.sonarr.tv/ master main" | tee /etc/apt/sources.list.d/sonarr.list > /dev/null
    apt update > /dev/null

    info "  Permissions fixes"
    # Add root to openflixr group
    usermod -a -G openflixr root
    # Make /mnt group be openflixr
    chown openflixr:openflixr -R /mnt
    # Add group write permissions to /mnt
    chmod g+w -R /mnt
}