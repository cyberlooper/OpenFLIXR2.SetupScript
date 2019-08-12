#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

step_change_password() {
    local PASS_CHANGE
    local STEP_TITLE=${1:-"Step ${step_number}: ${step_name}"}
    local ASK_QUESTION=${2:-}
    local done=0
    local valid=0
    if [[ ${ASK_QUESTION} == "" ]]; then
        if run_script 'question_prompt' N "Do you want to change the default password for OpenFLIXR?" "${STEP_TITLE}"; then
            PASS_CHANGE="Y"
        else
            PASS_CHANGE="N"
        fi
    else
        PASS_CHANGE="Y"
    fi
    while [[ ! $done = 1 ]]; do
        if [[ $PASS_CHANGE = "Y" ]]; then
            info "Changing password."
            valid=0
            while [[ ! $valid = 1 ]]; do
                pass=$(whiptail \
                        --backtitle ${OF_BACKTITLE} \
                        --title "${STEP_TITLE}" \
                        --passwordbox "Enter password" 8 0 3>&1 1>&2 2>&3)
                run_script 'check_response'  $?
                cpass=$(whiptail \
                        --backtitle ${OF_BACKTITLE} \
                        --title "${STEP_TITLE}" \
                        --passwordbox "Confirm password" 8 0 3>&1 1>&2 2>&3)
                run_script 'check_response'  $?

                if [[ $pass == $cpass ]]; then
                    log "Passwords match"
                    # DO NOT save the password to the config
                    OPENFLIXR_PASSWORD_NEW=$pass
                    valid=1
                    done=1
                set_config "CHANGE_PASS" "Y"
                else
                    log "Passwords don't match"
                    whiptail \
                        --backtitle ${OF_BACKTITLE} \
                        --title "${STEP_TITLE}" \
                        --ok-button "Try Again" \
                        --msgbox "Passwords do not match =( Try again." 0 0
                fi
            done
        else
            info "Keeping password."
            set_config "CHANGE_PASS" "N"
            OPENFLIXR_PASSWORD_NEW=""
            done=1
        fi
    done
}
