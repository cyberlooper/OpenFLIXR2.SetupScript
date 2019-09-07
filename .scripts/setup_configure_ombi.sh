#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

setup_configure_ombi()
{
    info "Configuring Ombi"
    info "- Stopping Ombi"
    service ombi stop
    info "- Setting API Key"
    local ombi_settings
    ombi_settings=$(sqlite3 /opt/Ombi/OmbiSettings.db "SELECT Content FROM GlobalSettings WHERE SettingsName='OmbiSettings'")
    # Set Ombi API Key
    debug "  Setting API Key to: ${API_KEYS[ombi]}"
    ombi_settings=$(sed 's/"ApiKey":".*","IgnoreCertificateErrors"/"ApiKey":"'${API_KEYS[ombi]}'","IgnoreCertificateErrors"/' <<< $ombi_settings)
    info "- Updating DB with the API Key"
    sqlite3 /opt/Ombi/OmbiSettings.db "UPDATE GlobalSettings SET Content='$ombi_settings' WHERE SettingsName='OmbiSettings'"
    sleep 2s
    info "- Starting Ombi"
    service ombi start
    info "- Making sure Ombi is ready..."
    if [[ $(run_script 'check_application_ready' "http://localhost:3579/request" "  -") == "200" ]]; then
        info "  Ombi is ready!"
        info "- Checking for the openflixr user"
        ombi_openflixr=$(sqlite3 /opt/Ombi/Ombi.db "SELECT COUNT(Id) FROM AspNetUsers WHERE NormalizedUserName='OPENFLIXR';")
        if [[ $ombi_openflixr = 1 ]]; then
            info "  Found!"
        else
            info "  Not found... Adding openflixr user"
            if [[ $(run_script 'check_application_ready' "http://localhost:3579/request" "  -") == "200" ]]; then
                local result
                result=$(curl -kL \
                    -X POST \
                    -H "Content-Type: application/json" \
                    --data "{ \"Username\": \"openflixr\", \"Password\": \"openflixr\", usePlexAdminAccount: false}" \
                    "http://localhost:3579/request/api/v1/Identity/Wizard/")
                log "  result=${result}"
                local result_successful
                result_successful=$(jq '.result?' <<< $result)
                if [[ $result_successful == "true" ]]; then
                    info "  Added!"
                else
                    error "  Unable to add openflixr user to Ombi"
                    warning "  You will need to update it manually after the setup completes."
                fi
            else
                error "  - Ombi was not ready to receive requests after 30s..."
                warning "  - You will need to manually configure Couchpotato in Ombi after setup completes."
                sleep 5s
            fi
        fi

        local ENABLED_OMBI
        if [ "${config[MOVIE_MANAGER]}" == 'couchpotato' ]; then
            info "- Enabling couchpotato in OMBI"
            ENABLED_OMBI="true"
        else
            info "- Disabling couchpotato in OMBI"
            ENABLED_OMBI="false"
        fi
        if [[ $(run_script 'check_application_ready' "http://localhost:3579/request" "    ") == "200" ]]; then
            log "  Ombi"
            curl -s \
                -X POST \
                "http://localhost:3579/api/v1/Settings/CouchPotato" \
                -H "Content-Type: application/json" \
                -H "Accept: application/json" \
                -H "ApiKey: ${API_KEYS[ombi]}" \
                -d "{
                        \"ApiKey\": \"${API_KEYS[couchpotato]}\",
                        \"Enabled\": $ENABLED_OMBI,
                        \"Ip\": \"localhost\",
                        \"Port\": 5050,
                        \"SubDir\": \"couchpotato\"
                    }" >> $LOG_FILE 2>&1
        else
            error "  - Ombi was not ready to receive requests after 30s..."
            warning "  - You will need to manually configure Couchpotato in Ombi after setup completes."
            sleep 5s
        fi

        if [ "${config[MOVIE_MANAGER]}" == 'radarr' ]; then
            info "- Enabling radarr in OMBI"
            ENABLED_OMBI="true"
        else
            info "- Disabling radarr in OMBI"
            ENABLED_OMBI="false"
        fi

        if [[ $(run_script 'check_application_ready' "http://localhost:3579/request" "    ") == "200" ]]; then
            log "  Ombi"
            curl -s \
                -X POST \
                -H 'Content-Type: application/json' \
                -H 'Accept: application/json' \
                -H "ApiKey: ${API_KEYS[ombi]}" \
                -d '{
                        "ApiKey": "'${API_KEYS[radarr]}'",
                        "Enabled": '$ENABLED_OMBI',
                        "Ip": "localhost",
                        "Port": 7878,
                        "SubDir": "radarr"
                    }' 'http://localhost:3579/request/api/v1/settings/radarr' >> $LOG_FILE
        else
            error "  - Ombi was not ready to receive requests after 30s..."
            warning "  - You will need to manually configure Radarr in Ombi after setup completes."
            sleep 5s
        fi

        if [ "${config[SERIES_MANAGER]}" == 'sickrage' ]; then
            info "  Enabling SickChill in OMBI"
            ENABLED_HTPC="on"
            ENABLED_OMBI="true"
        else
            info "  Disabling SickChill in OMBI"
            ENABLED_OMBI="false"
        fi

        if [[ $(run_script 'check_application_ready' "http://localhost:3579/request" "    ") == "200" ]]; then
            log "  Ombi"
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
            error "  - Ombi was not ready to receive requests after 30s..."
            warning "  - You will need to manually configure Sickchill in Ombi after setup completes."
            sleep 5s
        fi

        if [ "${config[SERIES_MANAGER]}" == 'sonarr' ]; then
            info "  Enabling sonarr in OMBI"
            ENABLED_OMBI="true"
        else
            info "  Disabling sonarr in OMBI"
            ENABLED_OMBI="false"
        fi

        if [[ $(run_script 'check_application_ready' "http://localhost:3579/request" "    ") == "200" ]]; then
            log "  Ombi"
            curl -s \
                -X POST \
                -H 'Content-Type: application/json' \
                -H 'Accept: application/json' \
                -H "ApiKey: ${API_KEYS[ombi]}" \
                -d '{
                    "ApiKey": "'${API_KEYS[sonarr]}'",
                    "qualityProfile": "default",
                    "Enabled": '$ENABLED_OMBI',
                    "Ip": "localhost",
                    "Port": 7979,
                    "SubDir": "sonarr"
                }' 'http://localhost:3579/request/api/v1/settings/sonarr' >> $LOG_FILE
        else
            error "  - Ombi was not ready to receive requests after 30s..."
            warning "  - You will need to manually configure Sonarr in Ombi after setup completes."
            sleep 5s
        fi

        info "- Restarting Ombi"
        service ombi restart
        sleep 10s

        run_script 'setup_configure_ombi_password'
    else
        error "  - Ombi was not ready to receive requests after 30s..."
        warning "  - You will need to manually configure Ombi after setup completes or run this again once Ombi is ready."
        sleep 5s
    fi
}
