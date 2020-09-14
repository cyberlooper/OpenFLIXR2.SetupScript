#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

run_setup()
{
    run_script 'setup_prechecks'
    run_script 'setup_folder_creation'
    run_script 'setup_stop_services'
    run_script 'setup_retrieve_password'
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
    run_script 'setup_configure_pihole'
    run_script 'setup_configure_network'
    run_script 'setup_configure_letsencrypt'
    run_script 'setup_fixes'
    run_script 'setup_start_services'

    warning "System reboot needed. Please reboot your system when you are ready."
    info "#############################"
    info "#      Setup complete!      #"
    info "#############################"
    info "Be sure to head over to the Post-setup steps found here for what to do next:"
    info "https://github.com/cyberlooper/Docs/wiki/Setup#post-setup-steps"
    run_script 'set_config' "SETUP_COMPLETED" "Y"
}
