#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

setup_configure_ombi()
{
    info "Configuring Ombi"
    info "- Setting API Key"
    local ombi_settings
    ombi_settings=$(sqlite3 /opt/Ombi/OmbiSettings.db "SELECT Content FROM GlobalSettings WHERE SettingsName='OmbiSettings'")
    # Set Ombi API Key
    debug "  Setting API Key to: ${API_KEYS[ombi]}"
    ombi_settings=$(sed 's/"ApiKey":".*","IgnoreCertificateErrors"/"ApiKey":"'${API_KEYS[ombi]}'","IgnoreCertificateErrors"/' <<< $ombi_settings)
    info "- Updating DB with the API Key"
    sqlite3 /opt/Ombi/OmbiSettings.db "UPDATE GlobalSettings SET Content='$ombi_settings' WHERE SettingsName='OmbiSettings'"
    info "- Checking for the openflixr user"
    ombi_openflixr=$(sqlite3 /opt/Ombi/Ombi.db "SELECT COUNT(Id) FROM AspNetUsers WHERE NormalizedUserName='OPENFLIXR';")
    if [[ $ombi_openflixr = 1 ]]; then
        info "  Found!"
    else
        info "  Not found... Adding openflixr user"
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
    fi
    info "- Restarting Ombi"
    service ombi restart
    sleep 10s

    run_script 'setup_configure_ombi_password'
}
