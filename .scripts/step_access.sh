#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

step_access() {
    local STEP_TITLE=${1:-"Step ${step_number}: ${step_name}"}
    local ACCESSOPTS=()
    ACCESSOPTS+=("Local " "Accessing via local network. SSL disabled.")
    ACCESSOPTS+=("Remote " "Accessing via the interwebs. SSL enabled.")

    local CONFIGCHOICE
    if [[ ${CI:-} == true ]] && [[ ${TRAVIS:-} == true ]]; then
        CONFIGCHOICE="Cancel"
    else
        CONFIGCHOICE=$(whiptail \
                        --backtitle ${OF_BACKTITLE} \
                        --title "${STEP_TITLE}" \
                        --menu "How do you want to access OpenFLIXR?" \
                        0 0 0 "${ACCESSOPTS[@]}" \
                        3>&1 1>&2 2>&3 || echo "Cancel")
    fi
    run_script 'check_response' $?

    case "${CONFIGCHOICE}" in
        "Local ")
            log "Local selected"
            info "OpenFLIXR access set to Local"
            set_config "ACCESS" "LOCAL"
            set_config "LETSENCRYPT" "off"
            ;;
        "Remote ")
            log "Remote selected"
            domain=$(whiptail \
                    --backtitle ${OF_BACKTITLE} \
                    --title "${STEP_TITLE} - Remote" \
                    --clear \
                    --ok-button "Next" \
                    --inputbox $"Enter your domain (required to obtain certificate). You may use a subdomain as well.\nIf you don't have a domain, register one first and then enter it here.\nExample: Either 'mydomain.com' or 'sub.mydomain.com' are okay." \
                    0 0 "${config[OPENFLIXR_DOMAIN]}" \
                    3>&1 1>&2 2>&3)
            run_script 'check_response' $?
            set_config "OPENFLIXR_DOMAIN" $domain

            email=$(whiptail \
                    --backtitle ${OF_BACKTITLE} \
                    --title "${STEP_TITLE} - Remote" \
                    --clear \
                    --ok-button "Next" \
                    --inputbox "Enter your e-mail address (required for lost key recovery)." \
                    0 0 "${config[OPENFLIXR_EMAIL]}" \
                    3>&1 1>&2 2>&3)
            run_script 'check_response' $?
            set_config "OPENFLIXR_EMAIL" $email

            remote_message="Do the following:\n"
            if [[ $HAS_INTERNET -eq 1 ]]; then
                remote_message="${remote_message}1) Add/Edit the A records for ${config[OPENFLIXR_DOMAIN]} and www.${config[OPENFLIXR_DOMAIN]} to point to ${PUBLIC_IP}\n"
            else
                remote_message="${remote_message}1) Add/Edit the A records for ${config[OPENFLIXR_DOMAIN]} and www.${config[OPENFLIXR_DOMAIN]} to point to your Public IP (Script failed to get your Public IP).\n"
            fi
            remote_message="${remote_message}2) Forward ports 80 and 443 on your router to your local IP (${LOCAL_IP})\n"
            remote_message="${remote_message}\n"
            remote_message="${remote_message}These MUST be done for successful configuration of remote access."
            whiptail \
                --backtitle ${OF_BACKTITLE} \
                --title "${STEP_TITLE} - Remote" \
                --clear \
                --ok-button "Done!" \
                --msgbox $"${remote_message}" 0 0
            run_script 'check_response' $?

            info "OpenFLIXR access set to Remote"
            set_config "ACCESS" "REMOTE"
            set_config "LETSENCRYPT" "on"
            ;;
        "Cancel")
            info "Cancel selected. Exiting setup"
            exit 0
            ;;
        *)
            error "Unknown option"
            run_script 'step_access'
            ;;
    esac
}
