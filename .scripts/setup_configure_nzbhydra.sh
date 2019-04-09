#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

setup_configure_nzbhydra()
{
    info "Configuring NZBHydra"
    info "- Updating API Key"
    sed -i 's/apiKey:.*/apiKey: "'${API_KEYS[nzbhydra2]}'"/g' /opt/nzbhydra2/data/nzbhydra.yml
}
