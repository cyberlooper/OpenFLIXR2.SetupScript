#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

unmaintained() {
    warn "!!!! This script is no longer maintained !!!!"
    # Dialog to display
    whiptail \
        --backtitle ${OF_BACKTITLE} \
        --title "Script no longer maintained..." \
        --clear \
        --msgbox "$(cat ${SCRIPTPATH}/.misc/project_dead.txt)" \
        0 0
}
