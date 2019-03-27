#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

setup_configure_htpc_manager()
{
    info "Configuring HTPC Manager"
    info "- Updating API keys"
    for service in "${!API_KEYS[@]}"; do
        if [[ "${service}" != "monit"
            && "${service}" != "htpcmanager"
            && "${service}" != "lidarr"
            && "${service}" != "lazylibrarian"
            && "${service}" != "mopidy"
            && "${service}" != "nzbhydra2"
        ]]; then
            info "-- ${service}"
            if [[ "${service}" == "jackett" ]]; then
                sqlite3 /opt/HTPCManager/userdata/database.db "UPDATE setting SET val='${API_KEYS[$service]}' where key='torrents_${service}_apikey';"
            else
                sqlite3 /opt/HTPCManager/userdata/database.db "UPDATE setting SET val='${API_KEYS[$service]}' where key='${service}_apikey';"
            fi
        fi
    done
}
