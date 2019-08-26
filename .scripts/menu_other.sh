#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

menu_other() {
    local OTHER_COMPLETED="N"
    local OTHEROPTS=()
    if [[ $(grep -c "127.0.0.1" "/etc/resolv.conf") -ge 1 ]]; then
        OTHEROPTS+=("Bypass Pi-hole " "")
    else
        OTHEROPTS+=("Undo Bypass Pi-hole " "")
    fi
    OTHEROPTS+=("Run ALL fixes " "")
    #OTHEROPTS+=("Select fix to run " "")

    local OTHERCHOICE
    if [[ ${CI:-} == true ]] && [[ ${TRAVIS:-} == true ]]; then
        OTHERCHOICE="Cancel"
    else
        OTHERCHOICE=$(whiptail --fb --clear --title "OpenFLIXR - Configuration" --menu "What would you like to do?" 0 0 0 "${OTHEROPTS[@]}" 3>&1 1>&2 2>&3 || echo "Cancel")
    fi

    case "${OTHERCHOICE}" in
        "Bypass Pi-hole ")
            info "Running Pi-hole bypass only"
            run_script 'pihole_bypass'
            OTHER_COMPLETED="Y"
            ;;
        "Undo Bypass Pi-hole ")
            info "Running Pi-hole unbypass only"
            run_script 'pihole_unbypass'
            OTHER_COMPLETED="Y"
            ;;
        "Run ALL fixes ")
            info "Running ALL fixes only"
            run_script 'setup_fixes'
            OTHER_COMPLETED="Y"
            ;;
        "Select fix to run ")
            run_script 'menu_config_select_fixes' || run_script 'menu_config'
            ;;
        "Cancel")
            info "Returning to Main Menu."
            return 1
            ;;
        *)
            error "Invalid Option"
            ;;
    esac

    if [[ "${OTHER_COMPLETED}" == "Y" ]]; then
        info "${OTHERCHOICE}completed"
        whiptail \
            --backtitle ${OF_BACKTITLE} \
            --title "Complete!" \
            --clear \
            --ok-button "Great!" \
            --msgbox "${OTHERCHOICE}completed. Returning to the main menu." 0 0
        return 1
    fi
}
