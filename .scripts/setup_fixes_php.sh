#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

setup_fixes_php()
{
    info "PHP fixes"
    if [[ $(dpkg -l | grep -c php7.3-fpm) == 0 ]]; then
        info "- Updating repositories."
        apt-get -y update > /dev/null 2>&1 || error "Failed to get updates from apt."
        info "- Installing new php7.3-fpm"
        export DEBIAN_FRONTEND=noninteractive
        export UCF_FORCE_CONFFNEW=1
        apt-get -y -o Dpkg::Options::=--force-confnew install php7.3-fpm || error "Failed to install php7.3-fpm."
        export DEBIAN_FRONTEND=
        export UCF_FORCE_CONFFNEW=
        info "- Removing unused packages."
        apt-get -y autoremove > /dev/null 2>&1 || error "Failed to remove unused packages from apt."
        info "- Cleaning up package cache."
        apt-get -y autoclean > /dev/null 2>&1 || error "Failed to cleanup cache from apt."
    else
        info "- php7.3-fpm already fixed!"
    fi
    info "- Done"
}