#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

setup_configure_torrent_downloader()
{
    info "Configuring Torrents Downloader"
    warning "TODO: configure downloader"

    info "- Jackett"
    info "  Updating API Key"
    sed -i 's/"APIKey":.*,/"APIKey": "'${API_KEYS[jackett]}'", /g' /root/.config/Jackett/ServerConfig.json
}
