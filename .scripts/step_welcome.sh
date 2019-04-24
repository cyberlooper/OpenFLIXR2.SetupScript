#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

step_welcome() {
    # Dialog to display
    whiptail \
        --backtitle ${OF_BACKTITLE} \
        --title "Step ${step_number}: ${step_name}" \
        --clear \
        --msgbox "$(cat ${SCRIPTPATH}/.misc/welcome.txt)" \
        0 0
}
