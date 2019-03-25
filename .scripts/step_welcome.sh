#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

step_welcome() {
    # Variables
    local HEIGHT=30
    local WIDTH=75

    # Dialog to display
    whiptail \
        --backtitle ${BACKTITLE} \
        --title "Step ${step_number}: ${step_name}" \
        --clear \
        --msgbox "$(cat ${SCRIPTPATH}/.misc/welcome.txt)" \
        ${HEIGHT:-0} ${WIDTH:-0}
}
