#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

step_folder_creation() {
    {
        for FOLDER in ${OPENFLIXR_FOLDERS[@]}; do
            info "Creating /mnt/${FOLDER}/"
            mkdir -p /mnt/${FOLDER}/
            #TODO: chown openflixr
        done
        echo -e "XXX\n100\nFolders created!\nXXX"
        info "Folders created!"
        sleep 2s
    } | whiptail --title "Step ${step_number}: ${step_name}" --gauge "Creating folders" 10 75 0
}