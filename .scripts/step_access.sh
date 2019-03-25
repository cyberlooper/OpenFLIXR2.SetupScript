#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

step_access() {
    access=$(whiptail \
                --backtitle ${OF_BACKTITLE} \
                --title "Step ${step_number}: ${step_name}" \
                --clear \
                --radiolist "How do you want to access OpenFLIXR?" \
                ${HEIGHT:-0} ${WIDTH:-0} 2 \
                1 "Local" on \
                2 "Remote" off \
                3>&1 1>&2 2>&3)
    run_script 'check_response' $?
    set_config "ACCESS" ${access}

    if [[ $access -eq 1 ]]; then
        # Local access selected. Nothing else to do.
        info "Folder access set to Local"
        set_config "OPENFLIXR_DOMAIN" $LOCAL_IP
    fi

    if [[ $access -eq 2 ]]; then
        # Configuring for Remote access.
        info "Folder access set to Remote"
        domain=$(whiptail \
                --backtitle ${OF_BACKTITLE} \
                --title "Step ${step_number}: ${step_name} - Remote" \
                --clear \
                --ok-button "Next" \
                --inputbox "Enter your domain (required to obtain certificate). If you don't have one, register one and then enter it here." \
                ${HEIGHT:-0} ${WIDTH:-0} "${config[OPENFLIXR_DOMAIN]}" \
                3>&1 1>&2 2>&3)
        run_script 'check_response' $?
        set_config "OPENFLIXR_DOMAIN" $domain

        email=$(whiptail \
                --backtitle ${OF_BACKTITLE} \
                --title "Step ${step_number}: ${step_name} - Remote" \
                --clear \
                --ok-button "Next" \
                --inputbox "Enter your e-mail address (required for lost key recovery)." \
                ${HEIGHT:-0} ${WIDTH:-0} "${config[OPENFLIXR_EMAIL]}" \
                3>&1 1>&2 2>&3)
        run_script 'check_response' $?
        set_config "OPENFLIXR_EMAIL" $email

        if [[ $HAS_INTERNET -eq 1 ]]; then
            remote_message="Add/Edit the A records for ${config[OPENFLIXR_DOMAIN]} and www.${config[OPENFLIXR_DOMAIN]} to point to ${PUBLIC_IP}"
        else
            remote_message="Add/Edit the A records for ${config[OPENFLIXR_DOMAIN]} and www.${config[OPENFLIXR_DOMAIN]} to point to your Public IP (Script failed to get your Public IP)."
        fi

        whiptail \
            --backtitle ${OF_BACKTITLE} \
            --title "Step ${step_number}: ${step_name} - Remote" \
            --clear \
            --ok-button "Next" \
            --msgbox "${remote_message}" ${HEIGHT:-0} ${WIDTH:-0}
        run_script 'check_response' $?

        whiptail \
            --backtitle ${OF_BACKTITLE} \
            --title "Step ${step_number}: ${step_name} - Remote" \
            --clear \
            --ok-button "Next" \
            --msgbox "Forward ports 80 and 443 on your router to your local IP (${LOCAL_IP})" ${HEIGHT:-0} ${WIDTH:-0}
        run_script 'check_response' $?
    fi
}
