#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

setup_configure_series_manager()
{
    local ENABLED_HTPC
    local ENABLED_OMBI

    info "Configuring TV Show Manager"
    info "- SickChill"

    if [[ ! -f "/opt/sickrage/config.ini" ]]; then
        info "  Config file not found... attempting to get SickChill to generate it."
        info "  Starting SickChill..."
        service sickrage start
        sleep 5s
        info "  Checking that SickChill is ready..."
        if [[ $(run_script 'check_application_ready' "http://localhost:8081/sickrage/" "  ") == "200" ]]; then
            info "  SickChill is accessible by URL!"
            info "  Checking for SickChill config file..."
            if [[ $(run_script 'check_file' "/opt/sickrage/config.ini" "  ") == "200" ]]; then
                info "  SickChill config file found!"
            else
                error "  SickChill config file NOT found after 30s..."
            fi
        else
            warning "  SickChill is NOT accessible by URL after 30s..."
        fi
        info "  Stopping SickChill..."
        service sickrage stop
    fi

    if [[ -f "/opt/sickrage/config.ini" ]]; then
        info "  Updating API Key"
        crudini --set /opt/sickrage/config.ini General api_key ${API_KEYS[sickrage]}

        # TODO: Revisit
        ## anidb
        # if [ "$anidbpass" != '' ]; then
        #     info "  Connecting to AniDB"
        #     crudini --set /opt/sickrage/config.ini ANIDB use_anidb 1
        #     crudini --set /opt/sickrage/config.ini ANIDB anidb_password $anidbuser
        #     crudini --set /opt/sickrage/config.ini ANIDB anidb_username $anidbpass
        # else
        #     crudini --set /opt/sickrage/config.ini ANIDB use_anidb 0
        #     crudini --set /opt/sickrage/config.ini ANIDB anidb_password
        #     crudini --set /opt/sickrage/config.ini ANIDB anidb_username
        # fi
    else
        error "  Config file not found..."
        warning "  You will need to manually configure Sickchill after setup completes."
    fi

    info "- Sonarr"
    info "  Updating API Key"
    sed -i 's/^  <ApiKey>.*/  <ApiKey>'${API_KEYS[sonarr]}'<\/ApiKey>/' /root/.config/NzbDrone/config.xml
    info "  Updating Sonarr settings"

    info "  - Updating Indexer settings"
    info "    NZBHydra"
    if [[ $(sqlite3 /root/.config/NzbDrone/nzbdrone.db "SELECT COUNT(id) FROM Indexers WHERE Name='NZBHydra'") != 0 ]]; then
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
    else
        error "    NZBHydra could not be found in Sonarr"
        warning "    You will need to manually configure NZBHydra in Sonarr after setup completes."
    fi
    info "  - Updating Downloader settings"
    info "    NZBget"
    if [[ $(sqlite3 /root/.config/NzbDrone/nzbdrone.db "SELECT COUNT(id) FROM DownloadClients WHERE Name='NZBget'") != 0 ]]; then
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
    else
        error "    NZBget could not be found in Sonarr"
        warning "    You will need to manually configure NZBget in Sonarr after setup completes."
    fi

    info "    SABnzb"
    if [[ $(sqlite3 /root/.config/NzbDrone/nzbdrone.db "SELECT COUNT(id) FROM DownloadClients WHERE Name='SABnzbd'") != 0 ]]; then
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
    else
        error "    SABnzb could not be found in Sonarr"
        warning "    You will need to manually configure NZBget in Sonarr after setup completes."
    fi
}
