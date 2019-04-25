#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

setup_configure_nginx_password()
{
    if [[ ! $password = "" ]]; then
    info "- Updating Password"
        echo openflixr:"$password" | sudo chpasswd
        htpasswd -b /etc/nginx/.htpasswd openflixr "$password"
        crudini --set /usr/share/nginx/html/setup/config.ini password oldpassword $password
    fi
}
