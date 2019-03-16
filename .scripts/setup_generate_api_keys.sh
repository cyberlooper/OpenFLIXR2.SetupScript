#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

setup_generate_api_keys()
{
    info "Generating API Keys"
    echo "# API KEYS" > /opt/openflixr/api.keys
    for service in "${SERVICES[@]}"; do
        info "-- $service"
        API_KEYS[$service]=$(uuidgen | tr -d - | tr -d '' | tr '[:upper:]' '[:lower:]')
        echo "$service: ${API_KEYS[$service]}" >> /opt/openflixr/api.keys
    done
}