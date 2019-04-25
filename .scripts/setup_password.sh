#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

setup_password()
{
    log "Password stuff"
    password="${OPENFLIXIR_PASSWORD:-}"
    oldpassword=""
    if [[ -f "/usr/share/nginx/html/setup/config.ini" ]]; then
        oldpassword=$(crudini --get /usr/share/nginx/html/setup/config.ini password oldpassword)
    fi
    if [[ "$oldpassword" == "" ]]; then
        oldpassword='openflixr'
    fi
}
