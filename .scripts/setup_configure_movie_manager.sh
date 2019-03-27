#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

setup_configure_movie_manager()
{
    local ENABLED_HTPC
    local ENABLED_OMBI

    info "Configuring Movies Manager"
    info "- Couchpotato"
    info "  Updating API Key"
    crudini --set /opt/CouchPotato/settings.conf core api_key ${API_KEYS[couchpotato]}
    crudini --set /opt/CouchPotato/settings.conf sabnzbd api_key ${API_KEYS[sabnzbd]}

    if [ "${config[MOVIE_MANAGER]}" == 'couchpotato' ]; then
        info "  Enabling in OMBI and HTPC"
        ENABLED_HTPC="on"
        ENABLED_OMBI="true"
    else
        info "  Disabling in OMBI and HTPC"
        ENABLED_HTPC="0"
        ENABLED_OMBI="false"
    fi

    curl -s -X POST --header 'Content-Type: application/json' --header 'Accept: application/json' -d '{
    "ApiKey": "'${API_KEYS[couchpotato]}'",
    "Enabled": '$ENABLED_OMBI',
    "Ip": "localhost",
    "Port": 5050,
    "SubDir": "couchpotato"
    }' 'http://localhost:3579/request/api/v1/settings/couchpotato?apikey='${API_KEYS[ombi]}'' >> $LOG_FILE

    #sqlite3 /opt/HTPCManager/userdata/database.db "UPDATE setting SET val='${ENABLED_HTPC}' where key='couchpotato_enable';"

    if [ "$imdb" != '' ]; then
        info "  Connecting to IMDB"
        crudini --set /opt/CouchPotato/settings.conf imdb automation_urls $imdb
        crudini --set /opt/CouchPotato/settings.conf imdb automation_urls_use 1
    else
        crudini --set /opt/CouchPotato/settings.conf imdb automation_urls
        crudini --set /opt/CouchPotato/settings.conf imdb automation_urls_use 0
    fi

    info "- Radarr"
    info "  Updating API Key"
    sed -i 's/^  <ApiKey>.*/  <ApiKey>'${API_KEYS[radarr]}'<\/ApiKey>/' /root/.config/Radarr/config.xml

    if [ "${config[MOVIE_MANAGER]}" == 'radarr' ]; then
        info "- Enabling in OMBI and HTPC"
        ENABLED_HTPC="on"
        ENABLED_OMBI="true"
    else
        info "- Disabling in OMBI and HTPC"
        ENABLED_HTPC="0"
        ENABLED_OMBI="false"
    fi

    curl -s -X POST --header 'Content-Type: application/json' --header 'Accept: application/json' -d '{
    "ApiKey": "'${API_KEYS[radarr]}'",
    "Enabled": '$ENABLED_OMBI',
    "Ip": "localhost",
    "Port": 5050,
    "SubDir": "radarr"
    }' 'http://localhost:3579/request/api/v1/settings/radarr?apikey='${API_KEYS[ombi]}'' >> $LOG_FILE

    #sqlite3 /opt/HTPCManager/userdata/database.db "UPDATE setting SET val='${ENABLED_HTPC}' where key='couchpotato_enable';"
}
