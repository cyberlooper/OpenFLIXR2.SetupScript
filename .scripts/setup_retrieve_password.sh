#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

setup_retrieve_password()
{
    log "Password stuff"
    OPENFLIXR_PASSWORD_OLD=""
    if [[ -f "/usr/share/nginx/html/setup/config.ini" ]]; then
        OPENFLIXR_PASSWORD_OLD=$(crudini --get /usr/share/nginx/html/setup/config.ini password oldpassword)
    fi
    if [[ "${OPENFLIXR_PASSWORD_OLD}" == "" ]]; then
        OPENFLIXR_PASSWORD_OLD='openflixr'
    fi
}
