#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

setup_configure_series_manager()
{
    local ENABLED_HTPC
    local ENABLED_OMBI

    info "Configuring TV Show Manager"
    info "- Sickrage"
    info "  Updating API Key"
    crudini --set /opt/sickrage/config.ini General api_key ${API_KEYS[sickrage]}

    if [ "${config[SERIES_MANAGER]}" == 'sickrage' ]; then
        info "  Enabling in OMBI and HTPC"
        ENABLED_HTPC="on"
        ENABLED_OMBI="true"
    else
        info "  Disabling in OMBI and HTPC"
        ENABLED_HTPC="0"
        ENABLED_OMBI="false"
    fi
    curl -s -X POST --header 'Content-Type: application/json' --header 'Accept: application/json' -d '{
    "ApiKey": "'${API_KEYS[sickrage]}'",
    "qualityProfile": "default",
    "Enabled": '$ENABLED_OMBI',
    "Ip": "localhost",
    "Port": 8081,
    "SubDir": "sickrage"
    }' 'http://localhost:3579/request/api/v1/settings/sickrage?apikey='${API_KEYS[ombi]}'' >> $LOG_FILE

    sqlite3 /opt/HTPCManager/userdata/database.db "UPDATE setting SET val='${ENABLED_HTPC}' where key='sickrage_enable';"

    ## anidb
    if [ "$anidbpass" != '' ]; then
        info "  Connecting to AniDB"
        crudini --set /opt/sickrage/config.ini ANIDB use_anidb 1
        crudini --set /opt/sickrage/config.ini ANIDB anidb_password $anidbuser
        crudini --set /opt/sickrage/config.ini ANIDB anidb_username $anidbpass
    else
        crudini --set /opt/sickrage/config.ini ANIDB use_anidb 0
        crudini --set /opt/sickrage/config.ini ANIDB anidb_password
        crudini --set /opt/sickrage/config.ini ANIDB anidb_username
    fi

    info "- Sonarr"
    info "  Updating API Key"
    sed -i 's/^  <ApiKey>.*/  <ApiKey>'${API_KEYS[sonarr]}'<\/ApiKey>/' /root/.config/NzbDrone/config.xml

    if [ "${config[SERIES_MANAGER]}" == 'sonarr' ]; then
        info "  Enabling in OMBI and HTPC"
        ENABLED_HTPC="on"
        ENABLED_OMBI="true"
    else
        info "  Disabling in OMBI and HTPC"
        ENABLED_HTPC="0"
        ENABLED_OMBI="false"
    fi
    curl -s -X POST --header 'Content-Type: application/json' --header 'Accept: application/json' -d '{
    "ApiKey": "'${API_KEYS[sickrage]}'",
    "qualityProfile": "default",
    "Enabled": '$ENABLED_OMBI',
    "Ip": "localhost",
    "Port": 8081,
    "SubDir": "sonarr"
    }' 'http://localhost:3579/request/api/v1/settings/sonarr?apikey='${API_KEYS[ombi]}'' >> $LOG_FILE

    sqlite3 /opt/HTPCManager/userdata/database.db "UPDATE setting SET val='${ENABLED_HTPC}' where key='sonarr_enable';"

}
