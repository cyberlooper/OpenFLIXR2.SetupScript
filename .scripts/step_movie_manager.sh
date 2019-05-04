#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

step_movie_manager() {
    local STEP_TITLE=${1:-"Step ${step_number}: ${step_name}"}
    local MOVIEOPTS=()
    MOVIEOPTS+=("Couchpotato " "")
    MOVIEOPTS+=("Radarr " "")

    done=0
    while [[ ! $done = 1 ]]; do
        local CONFIGCHOICE
        if [[ ${CI:-} == true ]] && [[ ${TRAVIS:-} == true ]]; then
            CONFIGCHOICE="Cancel"
        else
            CONFIGCHOICE=$(whiptail \
                            --backtitle ${OF_BACKTITLE} \
                            --title "${STEP_TITLE}" \
                            --menu "Choose you Movie Manager" \
                            0 0 0 "${MOVIEOPTS[@]}" \
                            3>&1 1>&2 2>&3 || echo "Cancel")
        fi
        run_script 'check_response' $?

        case "${CONFIGCHOICE}" in
            "Couchpotato ")
                set_config "MOVIE_MANAGER" "couchpotato"
                info "Configuring Series Manager to be ${CONFIGCHOICE}"
                done=1
                ;;
            "Radarr ")
                set_config "MOVIE_MANAGER" "radarr"
                info "Configuring Series Manager to be ${CONFIGCHOICE}"
                done=1
                ;;
            *)
                whiptail --title "${STEP_TITLE}" --yes-button "Try Again" --no-button "Cancel" --yesno "Something went wrong selecting the Movie Manager... Try again or select cancel to quit" 0 0
                run_script 'check_response' $?;
                ;;
        esac
    done
}
