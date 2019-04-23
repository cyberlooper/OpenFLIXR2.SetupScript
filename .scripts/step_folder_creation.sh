#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

step_folder_creation() {
    {
        for FOLDER in ${OPENFLIXR_FOLDERS[@]}; do
            mkdir -p /mnt/${FOLDER}/ > /dev/null
        done
        echo -e "XXX\n100\nFolders created!\nXXX"
        sleep 2s
    } | whiptail --title "Step ${step_number}: ${step_name}" --gauge "Creating folders" 10 75 0

    for FOLDER in ${OPENFLIXR_FOLDERS[@]}; do
        info "Created /mnt/${FOLDER}/"
    done
    info "Folders created!"
    info "Updating folder permissions..."
    chown openflixr:openflixr -R /mnt
    chmod g+w -R /mnt
}