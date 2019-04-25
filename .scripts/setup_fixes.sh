#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

setup_fixes()
{
    info "Various fixes not handled anywhere else in setup"
    info "- Sonarr apt repo fix"
    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 0xA236C58F409091A18ACA53CBEBFF6B99D9B78493 > /dev/null 2>&1
    if [[ -f "/etc/apt/sources.list.d/sonarr.list" ]]; then
        rm /etc/apt/sources.list.d/sonarr.list
    fi
    echo "deb http://apt.sonarr.tv/ master main" | tee /etc/apt/sources.list.d/sonarr.list > /dev/null
    apt-get update > /dev/null

    info "- Permissions fixes"
    # Add root to openflixr group
    usermod -a -G openflixr root || warning "  Unable to add 'root' user to 'openflixr' group"
    # Make /mnt group be openflixr
    chown openflixr:openflixr -R /mnt || warning "  Unable to change ownership of /mnt"
    # Add group write permissions to /mnt
    chmod g+w -R /mnt >> ${LOG_FILE} || warning "  Unable to change permissions of /mnt"

    if [[ -f "/etc/nginx/sites-enabled/reverse" ]]; then
        info "- Moving old nginx setting file"
        mv /etc/nginx/sites-enabled/reverse /opt/openflixr || warning "  Unable to move file"
        service nginx restart
    fi
}