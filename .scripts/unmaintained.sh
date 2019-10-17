#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

unmaintained() {
    warning "!!!! This script is no longer maintained !!!!"
    # Dialog to display
    whiptail \
        --backtitle ${OF_BACKTITLE} \
        --title "Script no longer maintained..." \
        --clear \
        --msgbox "$(cat ${SCRIPTPATH}/.misc/unmaintained.txt)" \
        0 0
}
