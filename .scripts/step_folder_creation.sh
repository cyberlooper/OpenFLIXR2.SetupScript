#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

step_folder_creation() {
    info "Creating /mnt folders"
    for FOLDER in ${OPENFLIXR_FOLDERS[@]}; do
        mkdir -p /mnt/${FOLDER}/ >> ${LOG_FILE}
        info "- Created /mnt/${FOLDER}/"
        sleep 2s
    done
    info "- Folders created!"
    info "- Updating folder permissions..."
    chown openflixr:openflixr -R /mnt || warning "  Unable to change ownership of /mnt"
    chmod g+w -R /mnt >> ${LOG_FILE} || warning "  Unable to change permissions of /mnt"
}