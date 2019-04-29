#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

setup_folder_creation() {
    info "Creating /mnt folders"
    for FOLDER in ${OPENFLIXR_FOLDERS[@]}; do
        if [[ ! -d "/mnt/${FOLDER}/" ]]; then
            mkdir -p /mnt/${FOLDER}/ >> ${LOG_FILE}
            info "- Created /mnt/${FOLDER}/"
        else
            info "- /mnt/${FOLDER}/ already exists!"
        fi
    done
    info "- Updating folder permissions..."
    # Add root to openflixr group
    usermod -a -G openflixr root || warning "  Unable to add 'root' user to 'openflixr' group"
    # Make /mnt group be openflixr
    chown openflixr:openflixr -R /mnt || warning "  Unable to change ownership of /mnt"
    # Add group write permissions to /mnt
    chmod g+w -R /mnt >> ${LOG_FILE} || warning "  Unable to change permissions of /mnt"
}