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
    debug "  Updating DB"
    sqlite3 /opt/Ombi/OmbiSettings.db "UPDATE GlobalSettings SET Content='$ombi_settings' WHERE SettingsName='OmbiSettings'"
    info "Restarting Ombi"
    service ombi restart
    sleep 10s
    run_script 'setup_configure_ombi_password'
}
