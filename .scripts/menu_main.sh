#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

menu_main() {
    local MAINOPTS=()
    MAINOPTS+=("Re-run setup " "Run Setup again after first completion")
    MAINOPTS+=("Configuration " "Run configuration for a specific part of the setup")

    local MAINCHOICE
    if [[ ${CI:-} == true ]] && [[ ${TRAVIS:-} == true ]]; then
        MAINCHOICE="Cancel"
    else
        MAINCHOICE=$(whiptail --fb --clear --backtitle \""${OF_BACKTITLE}"\" --title \""Setup Main Menu"\" --cancel-button "Exit" --menu "What would you like to do?" 0 0 0 "${MAINOPTS[@]}" 3>&1 1>&2 2>&3 || echo "Cancel")
    fi

    case "${MAINCHOICE}" in
        "Re-run setup ")
            run_script 'run_steps'
            ;;
        "Configuration ")
            run_script 'menu_config' || run_script 'menu_main'
            ;;
        "Submit Logs ")
            run_script 'submit_logs'
            ;;
        "Cancel")
            info "Exiting OpenFLIXR Setup."
            return
            ;;
        *)
            error "Invalid Option"
            ;;
    esac
}
