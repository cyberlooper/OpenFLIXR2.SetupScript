#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

fixes_sonarr()
{
    info "Sonarr fixes"
    info "- Checking sources"
    if [[ ! -f "/etc/apt/sources.list.d/sonarr.list"
        || (-f "/etc/apt/sources.list.d/sonarr.list" && $(grep -c "deb http://apt.sonarr.tv/ master main" /etc/apt/sources.list.d/sonarr.list) == 0) ]]; then
        if [[ -f "/etc/apt/sources.list.d/sonarr.list" ]]; then
            info "- Removing existing Sonarr sources..."
            rm /etc/apt/sources.list.d/sonarr.list
        fi
        info "- Adding Sonarr repo to sources"
        gpg --list-keys 0xA236C58F409091A18ACA53CBEBFF6B99D9B78493 > /dev/null 2>&1 || apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 0xA236C58F409091A18ACA53CBEBFF6B99D9B78493 > /dev/null 2>&1 || fatal "Failed to add sonarr key..."
        echo "deb http://apt.sonarr.tv/ master main" | tee /etc/apt/sources.list.d/sonarr.list > /dev/null || fatal "Failed to add sonarr repo..."
        info "- Updating apt"
        apt-get -y update > /dev/null 2>&1 || error "  Failed to update apt"
    else
        info "  Sources are good!"
    fi

    info "- Checking Sonarr version"
    SONARR_VERSION=$(apt-cache policy nzbdrone | grep "Installed:" | cut -d ':' -f 2 | cut -d '-' -f 1 | cut -d ' ' -f 2)
    SONARR_CANDIDATE=$(apt-cache policy nzbdrone | grep "Candidate:" | cut -d ':' -f 2 | cut -d '-' -f 1 | cut -d ' ' -f 2)
    if [[ ${SONARR_VERSION} == "(none)" || "${SONARR_VERSION}" != "${SONARR_CANDIDATE}" ]]; then
        info "- Updating Sonarr"
        apt-get -y install nzbdrone > /dev/null 2>&1 || error "  Failed to install/update Sonarr"
    else
        info "  Sonarr is good! Version: ${SONARR_VERSION}"
    fi
    info "- Done"
}