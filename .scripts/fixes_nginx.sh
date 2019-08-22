#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

fixes_nginx()
{
    info "Nginx fixes"
    if [[ -f "/etc/nginx/sites-enabled/reverse" ]]; then
        info "- Moving old nginx setting file"
        mv /etc/nginx/sites-enabled/reverse /opt/openflixr/reverse.old || warning "  Unable to move file"
        info "- Restarting nginx"
        service nginx restart
        info "- Moved old nginx settings file"
        info "- Done"
    else
        info "- Nothing to do! All good! =)"
    fi
}