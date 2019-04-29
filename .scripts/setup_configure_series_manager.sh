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

    log "  - Ombi"
    if [[ $(run_script 'check_application_ready' "http://localhost:3579/request" "    ") == "200" ]]; then
        curl -s \
            -X POST \
            -H 'Content-Type: application/json' \
            -H 'Accept: application/json' \
            -H "ApiKey: ${API_KEYS[ombi]}" \
            -d '{
                    "ApiKey": "'${API_KEYS[sickrage]}'",
                    "qualityProfile": "default",
                    "Enabled": '$ENABLED_OMBI',
                    "Ip": "localhost",
                    "Port": 8081,
                    "SubDir": "sickrage"
                }' 'http://localhost:3579/request/api/v1/settings/sickrage' >> $LOG_FILE
    else
        error "    Ombi was not ready to receive requests after 30s..."
        warning "    You will need to manually configure Sickchill (Sickrage) in Ombi after setup completes."
        sleep 5s
    fi

    log "  - HTPC"
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
    info "  Updating Sonarr settings"

    info "  - Updating Indexer settings"
    info "    NZBHydra"
    local sonarr_nzbhydra_id
    sonarr_nzbhydra_id=$(sqlite3 /root/.config/NzbDrone/nzbdrone.db "SELECT id FROM Indexers WHERE Name='NZBHydra'")
    local sonarr_nzbhydra_settings
    sonarr_nzbhydra_settings=$(sqlite3 /root/.config/NzbDrone/nzbdrone.db "SELECT Settings FROM Indexers WHERE id=$sonarr_nzbhydra_id")
    # Set NZBHydra API Key
    debug "Setting API Key to: ${API_KEYS[nzbhydra2]}"
    sonarr_nzbhydra_settings=$(sed 's/"apiKey":.*/"apiKey": "'${API_KEYS[nzbhydra2]}'",/' <<< $sonarr_nzbhydra_settings)
    # Set NZBHydra baseUrl
    debug "Setting Base URL to: http://localhost:5075/nzbhydra"
    sonarr_nzbhydra_settings=$(sed 's#"baseUrl":.*#"baseUrl": "http://localhost:5075/nzbhydra",#' <<< $sonarr_nzbhydra_settings)
    debug "Updating DB"
    sqlite3 /root/.config/NzbDrone/nzbdrone.db "UPDATE Indexers SET Settings='$sonarr_nzbhydra_settings' WHERE id=$sonarr_nzbhydra_id"

    info "  - Updating Downloader settings"
    info "    NZBget"
    local sonarr_nzbget_id
    sonarr_nzbget_id=$(sqlite3 /root/.config/NzbDrone/nzbdrone.db "SELECT id FROM DownloadClients WHERE Name='NZBget'")
    local sonarr_nzbget_settings
    sonarr_nzbget_settings=$(sqlite3 /root/.config/NzbDrone/nzbdrone.db "SELECT Settings FROM DownloadClients WHERE id=$sonarr_nzbget_id")
    # Change movieCategory to lowercase
    debug "Setting tvCategory to: tv"
    sonarr_nzbget_settings=$(sed 's/"movieCategory":.*/"tvCategory": "tv",/' <<< $sonarr_nzbget_settings)
    debug "Updating DB"
    if [[ ${config[NZB_DOWNLOADER]} == 'nzbget' ]]; then
        sqlite3 /root/.config/NzbDrone/nzbdrone.db "UPDATE DownloadClients SET Enable=1 WHERE id=$sonarr_nzbget_id"
    else
        sqlite3 /root/.config/NzbDrone/nzbdrone.db "UPDATE DownloadClients SET Enable=0 WHERE id=$sonarr_nzbget_id"
    fi
    sqlite3 /root/.config/NzbDrone/nzbdrone.db "UPDATE DownloadClients SET Settings='$sonarr_nzbget_settings' WHERE id=$sonarr_nzbget_id"

    info "    SABnzb"
    local sonarr_sabnzb_id
    sonarr_sabnzb_id=$(sqlite3 /root/.config/NzbDrone/nzbdrone.db "SELECT id FROM DownloadClients WHERE Name='SABnzbd'")
    local sonarr_sabnzb_settings
    sonarr_sabnzb_settings=$(sqlite3 /root/.config/NzbDrone/nzbdrone.db "SELECT Settings FROM DownloadClients WHERE id=$sonarr_sabnzb_id")
    # Set SABnzb API Key
    debug "Setting API Key to: ${API_KEYS[sabnzbd]}"
    sonarr_sabnzb_settings=$(sed 's/"apiKey":.*/"apiKey": "'${API_KEYS[sabnzbd]}'",/' <<< $sonarr_sabnzb_settings)
    debug "Updating DB"
    if [[ ${config[NZB_DOWNLOADER]} == 'sabnzbd' ]]; then
        sqlite3 /root/.config/NzbDrone/nzbdrone.db "UPDATE DownloadClients SET Enable=1 WHERE id=$sonarr_sabnzb_id"
    else
        sqlite3 /root/.config/NzbDrone/nzbdrone.db "UPDATE DownloadClients SET Enable=0 WHERE id=$sonarr_sabnzb_id"
    fi
    sqlite3 /root/.config/NzbDrone/nzbdrone.db "UPDATE DownloadClients SET Settings='$sonarr_sabnzb_settings' WHERE id=$sonarr_sabnzb_id"

    if [ "${config[SERIES_MANAGER]}" == 'sonarr' ]; then
        info "  Enabling in OMBI and HTPC"
        ENABLED_HTPC="on"
        ENABLED_OMBI="true"
    else
        info "  Disabling in OMBI and HTPC"
        ENABLED_HTPC="0"
        ENABLED_OMBI="false"
    fi

    log "  - Ombi"
    if [[ $(run_script 'check_application_ready' "http://localhost:3579/request" "    ") == "200" ]]; then
        curl -s \
            -X POST \
            -H 'Content-Type: application/json' \
            -H 'Accept: application/json' \
            -H "ApiKey: ${API_KEYS[ombi]}" \
            -d '{
                "ApiKey": "'${API_KEYS[sickrage]}'",
                "qualityProfile": "default",
                "Enabled": '$ENABLED_OMBI',
                "Ip": "localhost",
                "Port": 8081,
                "SubDir": "sonarr"
            }' 'http://localhost:3579/request/api/v1/settings/sonarr' >> $LOG_FILE
    else
        error "    Ombi was not ready to receive requests after 30s..."
        warning "    You will need to manually configure Sonarr in Ombi after setup completes."
        sleep 5s
    fi

    log "  - HTPC"
    sqlite3 /opt/HTPCManager/userdata/database.db "UPDATE setting SET val='${ENABLED_HTPC}' where key='sonarr_enable';"

}
