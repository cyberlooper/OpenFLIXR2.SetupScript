#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

symlink_setupopenflixr() {
    # /usr/bin/setupopenflixr
    if [[ -L "/usr/bin/setupopenflixr" ]] && [[ ${SCRIPTNAME} != "$(readlink -f /usr/bin/setupopenflixr)" ]]; then
        info "Attempting to remove /usr/bin/setupopenflixr symlink."
        rm "/usr/bin/setupopenflixr" || fatal "Failed to remove /usr/bin/setupopenflixr"
    fi
    if [[ ! -L "/usr/bin/setupopenflixr" ]]; then
        info "Creating /usr/bin/setupopenflixr symbolic link for DockSTARTer App Config."
        ln -s -T "${SCRIPTNAME}" /usr/bin/setupopenflixr || fatal "Failed to create /usr/bin/setupopenflixr symlink."
        chmod +x "${SCRIPTNAME}" > /dev/null 2>&1 || fatal "setupopenflixr must be executable."
    fi

    # /usr/local/bin/setupopenflixr
    if [[ -L "/usr/local/bin/setupopenflixr" ]] && [[ ${SCRIPTNAME} != "$(readlink -f /usr/local/bin/setupopenflixr)" ]]; then
        info "Attempting to remove /usr/local/bin/setupopenflixr symlink."
        rm "/usr/local/bin/setupopenflixr" || fatal "Failed to remove /usr/local/bin/setupopenflixr"
    fi
    if [[ ! -L "/usr/local/bin/setupopenflixr" ]]; then
        info "Creating /usr/local/bin/setupopenflixr symbolic link for DockSTARTer App Config."
        ln -s -T "${SCRIPTNAME}" /usr/local/bin/setupopenflixr || fatal "Failed to create /usr/local/bin/setupopenflixr symlink."
        chmod +x "${SCRIPTNAME}" > /dev/null 2>&1 || fatal "setupopenflixr must be executable."
    fi
}