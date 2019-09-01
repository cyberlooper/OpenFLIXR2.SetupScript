#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

fixes_permissions()
{
    info "Permissions fixes"
    if groups root | grep &>/dev/null '\openflixr\b'; then
        info "- 'root' is already part of the 'openflixr' group!"
    else
        info "- Adding 'root' user to 'openflixr' group"
        usermod -a -G openflixr root || warning "  Unable to add 'root' user to 'openflixr' group"
    fi
    if groups root | grep &>/dev/null '\openflixr\b'; then
        info "- 'plex' is already part of the 'openflixr' group!"
    else
        info "- Adding 'plex' user to 'openflixr' group"
        usermod -a -G openflixr plex || warning "  Unable to add 'plex' user to 'openflixr' group"
    fi
    USER=$(stat -c '%U' /mnt)
    GROUP=$(stat -c '%G' /mnt)
    if [[ ${USER} == "openflixr" && ${GROUP} == "openflixr" ]]; then
        info "- '/mnt' permissions 'openflixr:openflixr'!"
    else
        info "- Changing '/mnt' permissions to openflixr:openflixr"
        chown openflixr:openflixr -R /mnt || warning "  Unable to change ownership of /mnt"
    fi
    perms=$(stat /mnt | sed -n '/^Access: (/{s/Access: (\([0-9]\+\).*$/\1/;p}')
    if [[ $perms =~ 775 ]]; then
        info "- '/mnt' set to 775!"
    else
        info "- Making '/mnt' writeable by the 'openflixr' group"
        chmod 775 -R /mnt >> ${LOG_FILE} || warning "  Unable to change permissions of /mnt"
    fi
    USER=$(stat -c '%U' /home/openflixr/.nano/search_history)
    GROUP=$(stat -c '%G' /home/openflixr/.nano/search_history)
    if [[ ${USER} == "openflixr" && ${GROUP} == "openflixr" ]]; then
        info "- Fixing nano search_history file permissions"
        chown openflixr:openflixr /home/openflixr/.nano/search_history
    fi
    info "- Done"
}