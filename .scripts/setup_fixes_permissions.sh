#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

setup_fixes_permissions()
{
    info "Permissions fixes"
    info "- Adding 'root' user to 'openflixr' group"
    usermod -a -G openflixr root || warning "  Unable to add 'root' user to 'openflixr' group"
    info "- Adding 'plex' user to 'openflixr' group"
    usermod -a -G openflixr plex || warning "  Unable to add 'plex' user to 'openflixr' group"
    info "- Changing '/mnt' permissions to openflixr:openflixr"
    chown openflixr:openflixr -R /mnt || warning "  Unable to change ownership of /mnt"
    info "- Making '/mnt' writeable by the 'openflixr' group"
    chmod g+w -R /mnt >> ${LOG_FILE} || warning "  Unable to change permissions of /mnt"
    info "- Done"
}