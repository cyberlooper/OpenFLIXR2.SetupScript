#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

step_nzb_downloader() {
    local STEP_TITLE=${1:-"Step ${step_number}: ${step_name}"}
    local NZBOPTS=()
    NZBOPTS+=("SabNZB " "")
    NZBOPTS+=("NZBget " "")

    done=0
    while [[ ! $done = 1 ]]; do
        local CONFIGCHOICE
        if [[ ${CI:-} == true ]] && [[ ${TRAVIS:-} == true ]]; then
            CONFIGCHOICE="Cancel"
        else
            CONFIGCHOICE=$(whiptail \
                            --backtitle ${OF_BACKTITLE} \
                            --title "${STEP_TITLE}" \
                            --menu "Choose you NZB Downloader" \
                            0 0 0 "${NZBOPTS[@]}" \
                            3>&1 1>&2 2>&3 || echo "Cancel")
        fi
        run_script 'check_response' $?

        case "${CONFIGCHOICE}" in
            "SabNZB ")
                set_config "NZB_DOWNLOADER" "sabnzbd"
                info "Configuring Series Manager to be ${CONFIGCHOICE}"
                done=1
                ;;
            "NZBget ")
                set_config "NZB_DOWNLOADER" "nzbget"
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
