#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

step_welcome() {
    # Variables
    HEIGHT_ORIGINAL=$HEIGHT
    WIDTH_ORIGINAL=$WIDTH
    HEIGHT=30
    WIDTH=75

    # Dialog to display
    dialog \
        --backtitle "OpenFLIXR Setup" \
        --title "Step ${step_number}: ${step_name}" \
        --clear \
        --msgbox "$(cat ${SCRIPTPATH}/.misc/welcome.txt)" \
        $HEIGHT $WIDTH

    HEIGHT=$HEIGHT_ORIGINAL
    WIDTH=$WIDTH_ORIGINAL
}
