#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

setup_start_services()
{
    info "Starting services"
    for service in "${!SERVICES[@]}"; do
        if [[ "$service" != "plexpy" && "$service" != "ombi" ]]; then
            info "-- Starting ${SERVICES[$service]}"
            $(service ${SERVICES[$service]} start) || warning "Unable to start ${SERVICES[$service]}"
        fi
    done
    #service monit stop
    #service htpcmanager stop
    #service couchpotato stop
    #service sickrage stop
    #service headphones stop
    #service mylar stop
    #service sabnzbdplus stop
    #service jackett stop
    #service sonarr stop
    #service radarr stop
    #service lidarr stop
    #service lazylibrarian stop
    #service mopidy stop
    #service nzbhydra2 stop
}