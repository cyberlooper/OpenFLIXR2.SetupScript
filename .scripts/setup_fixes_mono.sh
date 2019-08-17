#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

setup_fixes_mono()
{
    info "Mono fixes"
    if [[ ! -f "/etc/mono/config.openflixr" ]]; then
        sudo mv "/etc/mono/config" "/etc/mono/config.openflixr"
    fi
    if [[ -f "/etc/mono/config.dpkg-new" ]]; then
        info "- Updating mono config"
        sudo cp "/etc/mono/config.dpkg-new" "/etc/mono/config"
    fi
    info "- Done"
}