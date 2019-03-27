#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

setup_configure_comic_manager()
{
    info "Configuring Comics Manager"
    info "- Mylar"
    crudini --set /opt/Mylar/config.ini General api_key ${API_KEYS[mylar]}
    crudini --set /opt/Mylar/config.ini SABnzbd sab_apikey ${API_KEYS[sabnzbd]}
    ## comicvine
    if [ "$comicvine" != '' ]; then
        info "  Connecting to Comic Vine"
        crudini --set /opt/Mylar/config.ini General comicvine_api $comicvine
    else
        crudini --set /opt/Mylar/config.ini General comicvine_api
    fi
}
