#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

setup_configure_ombi()
{
    info "Configuring Ombi"
    if [[ ! $password = "" ]]; then
        info "- Updating Password"
        curl -s -X PUT --header 'Content-Type: application/json' --header 'Accept: application/json' -d '{
        "CurrentPassword": "'$oldpassword'",
        "NewPassword": "'$password'"
        }' 'http://localhost:3579/request/api/credentials/openflixr?apikey='${API_KEYS[ombi]}'' >> $LOG_FILE
    fi
}
