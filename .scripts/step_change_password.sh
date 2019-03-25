#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

step_change_password() {
    local PASS_CHANGE
    done=0
    while [[ ! $done = 1 ]]; do
        if run_script 'question_prompt' N "Do you want to change the default password for OpenFLIXR?" "Step ${step_number}: ${step_name}"; then
            PASS_CHANGE="Y"
        else
            PASS_CHANGE="N"
        fi

        if [[ $PASS_CHANGE = "Y" ]]; then
            info "Changing password."
            set_config "CHANGE_PASS" "N"
            valid=0
            while [[ ! $valid = 1 ]]; do
                pass=$(whiptail \
                        --backtitle ${OF_BACKTITLE} \
                        --title "Step ${step_number}: ${step_name}" \
                        --passwordbox "Enter password" ${HEIGHT:-0} ${WIDTH:-0} 3>&1 1>&2 2>&3)
                run_script 'check_response'  $?
                cpass=$(whiptail \
                        --backtitle ${OF_BACKTITLE} \
                        --title "Step ${step_number}: ${step_name}" \
                        --passwordbox "Confirm password" ${HEIGHT:-0} ${WIDTH:-0} 3>&1 1>&2 2>&3)
                run_script 'check_response'  $?

                if [[ $pass == $cpass ]]; then
                    # DO NOT save the password to the config
                    OPENFLIXIR_PASSWORD=$pass
                    valid=1
                    done=1
                else
                    whiptail \
                        --backtitle ${OF_BACKTITLE} \
                        --title "Step ${step_number}: ${step_name}" \
                        --ok-button "Try Again" \
                        --msgbox "Passwords do not match =( Try again." ${HEIGHT:-0} ${WIDTH:-0}
                fi
            done
        else
            info "Keeping default password."
            set_config "CHANGE_PASS" "N"
            done=1
        fi
    done
}
