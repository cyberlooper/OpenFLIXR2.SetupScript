#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

create_config() {
    if [[ ! -d "${STORE_PATH}" ]]; then
        log "Creating store path..."
        mkdir -p "${STORE_PATH}"
    fi

    local COUNT=0
    for CONFIG_FILE_OLD in ${CONFIG_FILES_OLD[@]}; do
        if [[ -f "${CONFIG_FILE_OLD}" && ! -f "${CONFIG_FILE}" ]]; then
            log "Moving old config to new location"
            mv "${CONFIG_FILE_OLD}" "${CONFIG_FILE}"
        elif [[ -f "${CONFIG_FILE_OLD}" && -f "${CONFIG_FILE}" ]]; then
            log "Moving old config to new location as ${CONFIG_FILE}.bak.${COUNT}"
            mv "${CONFIG_FILE_OLD}" "${CONFIG_FILE}.bak.${COUNT}"
        fi
    done

    if [[ ! -f "${CONFIG_FILE}" ]]; then
        log "Creating config file..."
        touch ${CONFIG_FILE}
    fi
}
