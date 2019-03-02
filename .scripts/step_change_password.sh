#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

step_change_password() {
    done=0
    while [[ ! $done = 1 ]]; do
        pass_change=$(dialog \
                        --backtitle "OpenFLIXR Setup" \
                        --title "Step ${step_number}: ${step_name}" \
                        --clear \
                        --defaultno \
                        --yesno "Do you want to change the default password for OpenFLIXR?" $HEIGHT $WIDTH 3>&1 1>&2 2>&3)
        pass_change=$?

        if [[ $pass_change -eq 0 ]]; then
            config[CHANGE_PASS]="Y"
            valid=0
            while [[ ! $valid = 1 ]]; do
                pass=$(dialog \
                        --backtitle "OpenFLIXR Setup" \
                        --title "Step ${step_number}: ${step_name}" \
                        --passwordbox "Enter password" $HEIGHT $WIDTH 3>&1 1>&2 2>&3)
                run_script 'check_response'  $?
                cpass=$(dialog \
                        --backtitle "OpenFLIXR Setup" \
                        --title "Step ${step_number}: ${step_name}" \
                        --passwordbox "Confirm password" $HEIGHT $WIDTH 3>&1 1>&2 2>&3)
                run_script 'check_response'  $?

                if [[ $pass == $cpass ]]; then
                    OPENFLIXIR_PASSWORD=$pass
                    valid=1
                    done=1
                else
                    dialog \
                        --backtitle "OpenFLIXR Setup" \
                        --title "Step ${step_number}: ${step_name}" \
                        --ok-button "Try Again" \
                        --msgbox "Passwords do not match =( Try again." $HEIGHT $WIDTH
                fi
            done
        else
            config[CHANGE_PASS]="N"
            done=1
        fi
        set_config "CHANGE_PASS" $CHANGE_PASS
    done
}
