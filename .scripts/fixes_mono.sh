#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

fixes_mono()
{
    info "Mono fixes"
    if [[ ! -f "/etc/mono/config.openflixr" ]]; then
        mv "/etc/mono/config" "/etc/mono/config.openflixr"
    fi
    if [[ -f "/etc/mono/config.dpkg-new" ]]; then
        info "- Updating mono config"
        mv "/etc/mono/config.dpkg-new" "/etc/mono/config"
    fi
    info "- Checking sources for Mono"
    local SOURCE="/etc/apt/sources.list.d/mono-official-stable.list"
    log "UBU_VER=${UBU_VER}"
    if [[ ${UBU_VER} == "16.04" ]]; then
        local REPO="deb https://download.mono-project.com/repo/ubuntu stable-xenial main"
    elif [[ ${UBU_VER} == "18.04" ]]; then
        local REPO="deb https://download.mono-project.com/repo/ubuntu stable-bionic main"
    else
        error "Failed to detect Ubuntu version or Ubuntu version not supported..."
        return 0
    fi
    if [[ ! -f "${SOURCE}"
        || (-f "${SOURCE}" && $(grep -c "${REPO}" "${SOURCE}") == 0) ]]; then
        if [[ -f "${SOURCE}" ]]; then
            info "  - Removing existing Mono sources..."
            rm ${SOURCE}
        fi
        info "  - Adding Mono repo to sources"
        gpg --list-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF > /dev/null 2>&1 || apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF > /dev/null 2>"${LOG_FILE}" || error "Failed to add mono key..."
        echo "${REPO}" | sudo tee "${SOURCE}" > /dev/null
        info "  - Updating apt"
        apt-get -y update > /dev/null 2>&1 || error "  Failed to update apt"
    else
        info "  - Nothing to do!"
    fi
    info "- Checking if mono is installed"
    MONO_VERSION=$(apt-cache policy mono-devel | grep "Installed:" | cut -d ':' -f 2 | cut -d '-' -f 1 | cut -d ' ' -f 2)
    if [[ ${MONO_VERSION} == "(none)" ]]; then
        warning "mono not installed... Installing mono"
        apt-get -y install mono-devel
    else
        info "  Installed! Version: ${MONO_VERSION}"
    fi
    info "- Checking if ca-certificates-mono can be installed..."
    MONO_VERSION=$(apt-cache policy mono-runtime-common | grep "Installed:" | cut -d ':' -f 2 | cut -d '-' -f 1 | cut -d ' ' -f 2)
    if [[ ${MONO_VERSION} == "(none)" ]]; then
        MONO_VERSION_MAJOR=$(cut -d '.' -f 1 <<< $MONO_VERSION)
        MONO_VERSION_MINOR=$(cut -d '.' -f 2 <<< $MONO_VERSION)
        if [[ (${MONO_VERSION_MAJOR} -ge 6) || (${MONO_VERSION_MAJOR} -eq 5 && ${MONO_VERSION_MINOR} -ge 20) ]]; then
            info "  - Installing ca-certificates-mono"
            apt-get -y install ca-certificates-mono
        elif [[ ${MONO_VERSION_MAJOR} -le 5 && ${MONO_VERSION_MINOR} -le 20 ]]; then
            warning "  - Mono needs to be updated before these can be installed."
        else
            info "  Installed! Version: ${MONO_VERSION}"
        fi
    fi
    info "- Done"
}