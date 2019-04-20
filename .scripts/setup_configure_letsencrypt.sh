#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

setup_configure_letsencrypt()
{
    if [[ "${config[LETSENCRYPT]}" == "on" ]]; then
        info "Configuring Let's Encrypt"
        bash /opt/openflixr/letsencrypt.sh
        info "Configured!"
    fi
}
