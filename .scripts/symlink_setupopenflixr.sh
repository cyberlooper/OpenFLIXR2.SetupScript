#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

symlink_setupopenflixr() {
    local CHANGED=0
    local LINK_PATH="/opt/OpenFLIXR2.SetupScript/main.sh"
    # /usr/bin/setupopenflixr
    if [[ -L "/usr/bin/setupopenflixr" ]] && [[ ${LINK_PATH} != "$(readlink -f /usr/bin/setupopenflixr)" ]]; then
        info "Attempting to remove /usr/bin/setupopenflixr symlink."
        rm "/usr/bin/setupopenflixr" || fatal "Failed to remove /usr/bin/setupopenflixr"
    fi
    if [[ ! -L "/usr/bin/setupopenflixr" ]]; then
        if [[ -f "/usr/bin/setupopenflixr" ]]; then
            info "Attempting to remove /usr/bin/setupopenflixr file."
            rm "/usr/bin/setupopenflixr" || fatal "Failed to remove /usr/bin/setupopenflixr"
        fi
        info "Creating /usr/bin/setupopenflixr symbolic link for OpenFLIXR Setup."
        ln -s -T "${LINK_PATH}" /usr/bin/setupopenflixr || fatal "Failed to create /usr/bin/setupopenflixr symlink."
        chmod +x "${LINK_PATH}" > /dev/null 2>&1 || fatal "setupopenflixr must be executable."
        CHANGED=1
    fi

    # /usr/local/bin/setupopenflixr
    if [[ -L "/usr/local/bin/setupopenflixr" ]] && [[ ${LINK_PATH} != "$(readlink -f /usr/local/bin/setupopenflixr)" ]]; then
        info "Attempting to remove /usr/local/bin/setupopenflixr symlink."
        rm "/usr/local/bin/setupopenflixr" || fatal "Failed to remove /usr/local/bin/setupopenflixr"
    fi
    if [[ ! -L "/usr/local/bin/setupopenflixr" ]]; then
        if [[ -f "/usr/local/bin/setupopenflixr" ]]; then
            info "Attempting to remove /usr/local/bin/setupopenflixr file."
            rm "/usr/local/bin/setupopenflixr" || fatal "Failed to remove /usr/local/bin/setupopenflixr"
        fi
        info "Creating /usr/local/bin/setupopenflixr symbolic link for OpenFLIXR Setup."
        ln -s -T "${LINK_PATH}" /usr/local/bin/setupopenflixr || fatal "Failed to create /usr/local/bin/setupopenflixr symlink."
        chmod +x "${LINK_PATH}" > /dev/null 2>&1 || fatal "setupopenflixr must be executable."
        CHANGED=1
    fi
    if [[ $CHANGED == 1 ]]; then
        warning "setupopenflixr command has changed. Please run again."
        exit 0
    fi
}