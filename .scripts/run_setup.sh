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
    run_script 'setup_configure_ombi'
    run_script 'setup_configure_htpc_manager'
    run_script 'setup_configure_movie_manager'
    run_script 'setup_configure_series_manager'
    run_script 'setup_configure_music_manager'
    run_script 'setup_configure_comic_manager'
    run_script 'setup_configure_nzb_downloader'
    run_script 'setup_configure_torrent_downloader'
    run_script 'setup_configure_jackett'
    run_script 'setup_configure_nzbhydra'
    run_script 'setup_configure_tautulli'
    run_script 'setup_configure_apps' # TODO: Move what is in here to their proper config scripts
    run_script 'setup_configure_nginx'
    run_script 'setup_configure_letsencrypt'
    run_script 'setup_configure_pihole'
    run_script 'setup_configure_network'
    run_script 'setup_start_services'
}
