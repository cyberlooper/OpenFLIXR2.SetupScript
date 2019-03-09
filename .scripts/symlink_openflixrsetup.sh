#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

symlink_openflixrsetup() {
    # /usr/bin/openflixrsetup
    if [[ -L "/usr/bin/openflixrsetup" ]] && [[ ${SCRIPTNAME} != "$(readlink -f /usr/bin/openflixrsetup)" ]]; then
        info "Attempting to remove /usr/bin/openflixrsetup symlink."
        rm "/usr/bin/openflixrsetup" || fatal "Failed to remove /usr/bin/openflixrsetup"
    fi
    if [[ ! -L "/usr/bin/openflixrsetup" ]]; then
        info "Creating /usr/bin/openflixrsetup symbolic link for DockSTARTer App Config."
        ln -s -T "${SCRIPTNAME}" /usr/bin/openflixrsetup || fatal "Failed to create /usr/bin/openflixrsetup symlink."
        chmod +x "${SCRIPTNAME}" > /dev/null 2>&1 || fatal "openflixrsetup must be executable."
    fi

    # /usr/local/bin/openflixrsetup
    if [[ -L "/usr/local/bin/openflixrsetup" ]] && [[ ${SCRIPTNAME} != "$(readlink -f /usr/local/bin/openflixrsetup)" ]]; then
        info "Attempting to remove /usr/local/bin/openflixrsetup symlink."
        rm "/usr/local/bin/openflixrsetup" || fatal "Failed to remove /usr/local/bin/openflixrsetup"
    fi
    if [[ ! -L "/usr/local/bin/openflixrsetup" ]]; then
        info "Creating /usr/local/bin/openflixrsetup symbolic link for DockSTARTer App Config."
        ln -s -T "${SCRIPTNAME}" /usr/local/bin/openflixrsetup || fatal "Failed to create /usr/local/bin/openflixrsetup symlink."
        chmod +x "${SCRIPTNAME}" > /dev/null 2>&1 || fatal "openflixrsetup must be executable."
    fi
}