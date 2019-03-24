#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

setup_generate_api_keys()
{
    if [[ ! -f "/opt/openflixr/api.keys" ]]; then
        touch "/opt/openflixr/api.keys"
        echo "# API KEYS" > /opt/openflixr/api.keys
    fi

    info "Generating/Retrieving API Keys"
    for service in "${!SERVICES[@]}"; do
        info "-- $service"
        if grep -q "^${service}" "/opt/openflixr/api.keys"; then
            info "   Found API Key for ${service}. Retrieving..."
            API_KEYS[$service]=$(grep "^${service}" "/opt/openflixr/api.keys" | cut -d " " -f 2)
        else
            API_KEYS[$service]=$(uuidgen | tr -d - | tr -d '' | tr '[:upper:]' '[:lower:]')
            echo "${service}: ${API_KEYS[$service]}" >> /opt/openflixr/api.keys
            info "   API Key created for ${service}"
        fi
    done
}
