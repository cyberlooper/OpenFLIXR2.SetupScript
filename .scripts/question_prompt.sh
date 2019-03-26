#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

question_prompt() {
    local DEFAULT
    DEFAULT=${1:-Y}
    local QUESTION
    QUESTION=${2:-}
    local TITLE
    TITLE=${3:-}
    local BACKTITLE
    BACKTITLE=${4:-}
    local YN
    while true; do
        if [[ ${PROMPT:-} == "CLI" ]]; then
            info "${QUESTION}"
            read -rp "[Yn]" YN
        elif [[ ${PROMPT:-} == "GUI" ]]; then
            local WHIPTAIL_DEFAULT
            if [[ ${DEFAULT} == "N" ]]; then
                WHIPTAIL_DEFAULT=" --defaultno "
            fi
            local ANSWER
            set +e
            ANSWER=$(
                eval whiptail --fb --clear --backtitle \""${BACKTITLE}"\" --title \""${TITLE}"\" "${WHIPTAIL_DEFAULT:-}" --yesno \""${QUESTION}"\" 0 0 3>&1 1>&2 2>&3
                echo $?
            )
            set -e
            debug "Question prompt answer: ${ANSWER}"
            if [[ ${ANSWER} == 0 ]]; then
                YN=Y
            else
                YN=N
            fi
        else
            YN=${DEFAULT}
        fi
        case ${YN} in
            [Yy]*)
                break
                ;;
            [Nn]*)
                return 1
                ;;
            *)
                error "Please answer yes or no."
                ;;
        esac
    done
}
