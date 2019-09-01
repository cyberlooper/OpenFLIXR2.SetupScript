#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

menu_config_select_fixes() {
    local FIXOPTS=()
    for filename in ${SCRIPTPATH}/.scripts/fixes_*.sh; do
        filename=${filename##*_}
        filename=${filename/.sh/}
        FIXOPTS+=("Run ${filename} fix " "")
    done

    local FIXCHOICE
    if [[ ${CI:-} == true ]] && [[ ${TRAVIS:-} == true ]]; then
        FIXCHOICE="Cancel"
    else
        FIXCHOICE=$(whiptail --fb --clear --backtitle \""${OF_BACKTITLE}"\" --title \""OpenFLIXR - Fixes"\" --menu "What would you like to do?" 0 0 0 "${FIXOPTS[@]}" 3>&1 1>&2 2>&3 || echo "Cancel")
    fi

    case "${FIXCHOICE}" in
        "Cancel")
            info "Returning to Fixes Menu."
            return 1
            ;;
        *)
            FIXNAME=${FIXCHOICE#* }
            FIXNAME=${FIXNAME%% *}
            if [[ -f "${SCRIPTPATH}/.scripts/fixes_${FIXNAME}.sh" ]]; then
                run_script "fixes_${FIXNAME}" && FIXES_COMPLETED="Y"
            else
                error "Invalid Option"
            fi
            ;;
    esac

    if [[ "${FIXES_COMPLETED:-}" == "Y" ]]; then
        info "Fixes - ${FIXCHOICE}completed"
        whiptail \
            --backtitle ${OF_BACKTITLE} \
            --title "OpenFLIXR - Fixes" \
            --clear \
            --ok-button "Great!" \
            --msgbox "${FIXCHOICE}completed. Returning to menu." 0 0
        return 1
    else
        info "Fixes - ${FIXCHOICE}failed"
        whiptail \
            --backtitle ${OF_BACKTITLE} \
            --title "OpenFLIXR - Fixes" \
            --clear \
            --ok-button "Fine..." \
            --msgbox "${FIXCHOICE}failed... Returning to menu." 0 0
        return 0
    fi
}
