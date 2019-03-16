#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

set_stop_service()
{
    info "Stopping services"
    for service in "${SERVICES[@]}"; do
        if [[ "$service" != "plexpy" ]]; then
            $(service ${SERVICES[$service]} stop)
        fi
    done
    #service monit stop
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
    #service htpcmanager stop
    #service mopidy stop
    #service nzbhydra2 stop
}