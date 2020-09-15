#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

step_series_manager() {
    local STEP_TITLE=${1:-"Step ${step_number}: ${step_name}"}
    local SERIESOPTS=()
    #SERIESOPTS+=("Sickchill " "")
    SERIESOPTS+=("Sonarr " "")

    done=0
    while [[ ! $done = 1 ]]; do
        local CONFIGCHOICE
        if [[ ${CI:-} == true ]] && [[ ${TRAVIS:-} == true ]]; then
            CONFIGCHOICE="Cancel"
        else
            CONFIGCHOICE=$(whiptail \
                            --backtitle ${OF_BACKTITLE} \
                            --title "${STEP_TITLE}" \
                            --menu "Choose you Series Manager" \
                            0 0 0 "${SERIESOPTS[@]}" \
                            3>&1 1>&2 2>&3 || echo "Cancel")
        fi
        run_script 'check_response' $?

        case "${CONFIGCHOICE}" in
            # "Sickchill ")
            #     set_config "SERIES_MANAGER" "sickrage"
            #     info "Configuring Series Manager to be ${CONFIGCHOICE}"
            #     done=1
            #     ;;
            "Sonarr ")
                set_config "SERIES_MANAGER" "sonarr"
                info "Configuring Series Manager to be ${CONFIGCHOICE}"
                done=1
                ;;
            *)
                whiptail --title "${STEP_TITLE}" --yes-button "Try Again" --no-button "Cancel" --yesno "Something went wrong selecting the Series Manager... Try again or select cancel to quit" 0 0
                run_script 'check_response' $?;
                ;;
        esac
    done
}
