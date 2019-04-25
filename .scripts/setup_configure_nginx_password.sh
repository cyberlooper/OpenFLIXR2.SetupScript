#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

setup_configure_nginx_password()
{
    if [[ ${config[CHANGE_PASS]} == "Y" && ${OPENFLIXR_PASSWORD_NEW} != "" ]]; then
        info "- Updating Password"
        echo openflixr:"${OPENFLIXR_PASSWORD_NEW}" | sudo chpasswd
        htpasswd -b /etc/nginx/.htpasswd openflixr "${OPENFLIXR_PASSWORD_NEW}"
        crudini --set /usr/share/nginx/html/setup/config.ini password oldpassword ${OPENFLIXR_PASSWORD_NEW}
    fi
}
