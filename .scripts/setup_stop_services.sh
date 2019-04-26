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
}