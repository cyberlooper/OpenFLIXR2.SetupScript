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
    run_script 'fixes_permissions'
}