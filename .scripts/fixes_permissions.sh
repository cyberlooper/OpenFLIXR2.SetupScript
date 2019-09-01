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

    FIX_UG_PATHS=(
        "/home/openflixr/.nano/search_history"
        "/mnt"
    )
    for FIX_PATH in ${FIX_UG_PATHS[@]}; do
        USER=$(stat -c '%U' "${FIX_PATH}")
        GROUP=$(stat -c '%G' "${FIX_PATH}")
        if [[ ${USER} == "openflixr" && ${GROUP} == "openflixr" ]]; then
            info "- '${FIX_PATH}' permissions are already 'openflixr:openflixr'!"
        else
            info "- Changing '${FIX_PATH}' permissions to 'openflixr:openflixr'"
            chown openflixr:openflixr -R "${FIX_PATH}" || warning "  Unable to change ownership of '${FIX_PATH}'"
        fi
    done

    FIX_PERMS_PATHS=(
        "/mnt"
    )
    for FOLDER in ${OPENFLIXR_FOLDERS[@]}; do
        FIX_PERMS_PATHS+=("/mnt/${FOLDER}")
    done
    for FIX_PATH in ${FIX_PERMS_PATHS[@]}; do
        perms=$(stat "${FIX_PATH}" | sed -n '/^Access: (/{s/Access: (\([0-9]\+\).*$/\1/;p}')
        if [[ $perms =~ 775 ]]; then
            info "- '${FIX_PATH}' already set to 775!"
        else
            info "- Setting '${FIX_PATH}' to 775"
            chmod 775 -R /mnt >> ${LOG_FILE} || warning "  Unable to change permissions of '${FIX_PATH}'"
        fi
    done
    info "- Done"
}