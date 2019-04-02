#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

setup_configure_tautulli()
{
    ## plexpy
    info "Configuring Tautulli (PlexPy)"
    info "- Updating API Key"
    sed -i "s/api_key =.*/api_key = \"${API_KEYS[plexpy]}\"/g" "/opt/plexpy/config.ini"
}
