#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

setup_stop_services()
{
    info "Stopping services"
    for service in "${!SERVICES[@]}"; do
        if [[ "$service" != "plexpy" && "$service" != "ombi" ]]; then
            info "-- Stopping ${SERVICES[$service]}"
            $(service ${SERVICES[$service]} stop) || warning "Unable to stop ${SERVICES[$service]}"
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