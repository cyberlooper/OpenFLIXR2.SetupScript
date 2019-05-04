#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

menu_config() {
    local CONFIG_COMPLETED="N"
    local CONFIGOPTS=()
    CONFIGOPTS+=("Change Password " "")
    CONFIGOPTS+=("Configure Networking " "")
    CONFIGOPTS+=("Configure Access " "")
    CONFIGOPTS+=("Configure Movie Manager " "")
    CONFIGOPTS+=("Configure Series Manager " "")
    CONFIGOPTS+=("Configure NZB Downloader " "")
    CONFIGOPTS+=("Configure Pi-hole " "")
    CONFIGOPTS+=("Configure Folders " "")
    CONFIGOPTS+=("Various fixes " "")

    local CONFIGCHOICE
    if [[ ${CI:-} == true ]] && [[ ${TRAVIS:-} == true ]]; then
        CONFIGCHOICE="Cancel"
    else
        CONFIGCHOICE=$(whiptail --fb --clear --title "OpenFLIXR - Configuration" --menu "What would you like to do?" 0 0 0 "${CONFIGOPTS[@]}" 3>&1 1>&2 2>&3 || echo "Cancel")
    fi

    case "${CONFIGCHOICE}" in
        "Change Password ")
            info "Changing password only"
            run_script 'step_change_password' "${CONFIGCHOICE}"
            if [[ ${config[CHANGE_PASS]} == "Y" ]]; then
                run_script 'setup_change_password'
                run_script 'setup_retrieve_password'
                info "Configuring Nginx"
                run_script 'setup_configure_nginx_password'
                info "Configuring Ombi"
                # TODO: Refactor API Key retrieval for specific service
                declare -A API_KEYS
                info "- Retrieving API Key for Ombi..."
                API_KEYS[ombi]=$(grep "^ombi" "/opt/openflixr/api.keys" | cut -d " " -f 2)
                run_script 'setup_configure_ombi_password'
            fi
            CONFIG_COMPLETED="Y"
            ;;
        "Configure Networking ")
            info "Configuring Networking only"
            run_script 'step_network_configuration' "${CONFIGCHOICE}"
            run_script 'setup_configure_network'
            CONFIG_COMPLETED="Y"
            ;;
        "Configure Access ")
            info "Configuring Access only"
            run_script 'step_access' "${CONFIGCHOICE}"
            run_script 'setup_configure_letsencrypt'
            CONFIG_COMPLETED="Y"
            ;;
        "Configure Movie Manager ")
            info "Configuring Movie Manager only"
            run_script 'step_movie_manager' "${CONFIGCHOICE}"
            # TODO: Refactor API Key retrieval for specific service
            declare -A API_KEYS
            info "- Retrieving API Key for Couchpotato..."
            API_KEYS[couchpotato]=$(grep "^couchpotato" "/opt/openflixr/api.keys" | cut -d " " -f 2)
            info "- Retrieving API Key for Radarr..."
            API_KEYS[radarr]=$(grep "^radarr" "/opt/openflixr/api.keys" | cut -d " " -f 2)
            info "- Retrieving API Key for SabNZB..."
            API_KEYS[sabnzbd]=$(grep "^sabnzbd" "/opt/openflixr/api.keys" | cut -d " " -f 2)
            info "- Retrieving API Key for NZBHydra..."
            API_KEYS[nzbhydra2]=$(grep "^nzbhydra2" "/opt/openflixr/api.keys" | cut -d " " -f 2)
            run_script 'setup_configure_movie_manager'
            CONFIG_COMPLETED="Y"
            ;;
        "Configure Series Manager ")
            info "Configuring Series Manager only"
            run_script 'step_series_manager' "${CONFIGCHOICE}"
            # TODO: Refactor API Key retrieval for specific service
            declare -A API_KEYS
            info "- Retrieving API Key for Sickrage..."
            API_KEYS[sickrage]=$(grep "^sickrage" "/opt/openflixr/api.keys" | cut -d " " -f 2)
            info "- Retrieving API Key for Sonarr..."
            API_KEYS[sonarr]=$(grep "^sonarr" "/opt/openflixr/api.keys" | cut -d " " -f 2)
            info "- Retrieving API Key for SabNZB..."
            API_KEYS[sabnzbd]=$(grep "^sabnzbd" "/opt/openflixr/api.keys" | cut -d " " -f 2)
            info "- Retrieving API Key for NZBHydra..."
            API_KEYS[nzbhydra2]=$(grep "^nzbhydra2" "/opt/openflixr/api.keys" | cut -d " " -f 2)
            run_script 'setup_configure_series_manager'
            CONFIG_COMPLETED="Y"
            ;;
        "Configure NZB Downloader ")
            info "Configuring NZB Downloader only"
            run_script 'step_nzb_downloader' "${CONFIGCHOICE}"
            # TODO: Refactor API Key retrieval for specific service
            declare -A API_KEYS
            info "- Retrieving API Key for SabNZB..."
            API_KEYS[sabnzbd]=$(grep "^sabnzbd" "/opt/openflixr/api.keys" | cut -d " " -f 2)
            run_script 'setup_configure_nzb_downloader'
            CONFIG_COMPLETED="Y"
            ;;
        "Configure Pi-hole ")
            info "Configuring Pi-hole only"
            run_script 'setup_configure_pihole' "${CONFIGCHOICE}"
            CONFIG_COMPLETED="Y"
            ;;
        "Configure Folders ")
            info "Configuring Folders only"
            run_script 'setup_folder_creation'
            CONFIG_COMPLETED="Y"
            ;;
        "Various fixes ")
            info "Running fixes only"
            run_script 'setup_fixes_sonarr'
            run_script 'setup_fixes_permissions'
            run_script 'setup_fixes_nginx'
            run_script 'setup_fixes_updater'
            CONFIG_COMPLETED="Y"
            ;;
        "Cancel")
            info "Returning to Main Menu."
            return 1
            ;;
        *)
            error "Invalid Option"
            ;;
    esac

    if [[ "${CONFIG_COMPLETED}" == "Y" ]]; then
        info "${CONFIGCHOICE}completed"
        whiptail \
            --backtitle ${OF_BACKTITLE} \
            --title "Complete!" \
            --clear \
            --ok-button "Great!" \
            --msgbox "${CONFIGCHOICE}completed. Returning to the main menu." 0 0
        return 1
    fi
}
