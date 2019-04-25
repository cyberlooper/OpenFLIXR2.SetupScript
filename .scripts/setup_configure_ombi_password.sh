#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

setup_configure_ombi_password()
{
    if [[ ${config[CHANGE_PASS]} == "Y" && ${OPENFLIXR_PASSWORD_NEW} != "" ]]; then
        info "- Updating Password"
        curl -s -X PUT --header 'Content-Type: application/json' --header 'Accept: application/json' -d '{
        "CurrentPassword": "'${OPENFLIXR_PASSWORD_OLD}'",
        "NewPassword": "'${OPENFLIXR_PASSWORD_NEW}'"
        }' 'http://localhost:3579/request/api/credentials/openflixr?apikey='${API_KEYS[ombi]}'' >> $LOG_FILE
    fi
}
