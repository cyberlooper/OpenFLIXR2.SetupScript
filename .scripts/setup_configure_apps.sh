#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

setup_configure_apps()
{
    info "Configuring other things..."
    ## spotify mopidy
    if [ "$spotpass" != '' ]; then
        info  "- Connecting Mopidy to Spotify"
        crudini --set /etc/mopidy/mopidy.conf spotify username $spotuser
        crudini --set /etc/mopidy/mopidy.conf spotify password $spotpass
    else
        crudini --set /etc/mopidy/mopidy.conf spotify username
        crudini --set /etc/mopidy/mopidy.conf spotify password
    fi
}