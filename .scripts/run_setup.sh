#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

declare -A SERVICES
SERVICES=(
    # System Processes
    [monit]=monit
    [htpcmanager]=htpcmanager
    # Apps
    [couchpotato]=couchpotato
    [sickrage]=sickrage
    [headphones]=headphones
    [mylar]=mylar
    [sabnzbd]=sabnzbdplus
    [jackett]=jackett
    [sonarr]=sonarr
    [radarr]=radarr
    [plexpy]=plexpy
    # Apps - other
    [ombi]=ombi
    [lidarr]=lidarr
    [lazylibrarian]=lazylibrarian
    [mopidy]=mopidy
    [nzbhydra2]=nzbhydra2
)
declare -A API_KEYS

run_setup()
{
    run_script 'setup_stop_services'
    run_script 'setup_generate_api_keys'
    run_script 'setup_update_api_keys'
    run_script 'setup_configure_network'
    run_script 'setup_configure_apps'

    echo "System rebooting in about 5 seconds."
    sleep 5s
    reboot now
}
