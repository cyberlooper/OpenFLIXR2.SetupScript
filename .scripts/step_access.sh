#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

step_access() {
    access=$(dialog \
                --backtitle "OpenFLIXR Setup" \
                --title "Step ${step_number}: ${step_name}" \
                --clear \
                --radiolist "How do you want to access OpenFLIXR?" \
                $HEIGHT $WIDTH 2 \
                1 "Local" on \
                2 "Remote" off \
                3>&1 1>&2 2>&3)
    check_response $?
    set_config "ACCESS" ${access}

    if [[ $access -eq 1 ]]; then
        # Local access selected. Nothing else to do.
        info "Folder access set to Local"
        set_config "OPENFLIXR_DOMAIN" $LOCAL_IP
    fi

    if [[ $access -eq 2 ]]; then
        # Configuring for Remote access.
        info "Folder access set to Remote"
        domain=$(dialog \
                --backtitle "OpenFLIXR Setup" \
                --title "Step ${step_number}: ${step_name} - Remote" \
                --clear \
                --ok-button "Next" \
                --inputbox "Enter your domain (required to obtain certificate). If you don't have one, register one and then enter it here." \
                $HEIGHT $WIDTH "${config[OPENFLIXR_DOMAIN]}" \
                3>&1 1>&2 2>&3)
        check_response $?
        set_config "OPENFLIXR_DOMAIN" $domain

        email=$(dialog \
                --backtitle "OpenFLIXR Setup" \
                --title "Step ${step_number}: ${step_name} - Remote" \
                --clear \
                --ok-button "Next" \
                --inputbox "Enter your e-mail address (required for lost key recovery)." \
                $HEIGHT $WIDTH "${config[OPENFLIXR_EMAIL]}" \
                3>&1 1>&2 2>&3)
        check_response $?
        set_config "OPENFLIXR_EMAIL" $email

        if [[ $HAS_INTERNET -eq 1 ]]; then
            remote_message="Add/Edit the A records for ${domain} and www.${domain} to point to ${PUBLIC_IP}"
        else
            remote_message="Add/Edit the A records for ${domain} and www.${domain} to point to your Public IP (Script failed to get your Public IP)."
        fi

        dialog \
            --backtitle "OpenFLIXR Setup" \
            --title "Step ${step_number}: ${step_name} - Remote" \
            --clear \
            --ok-button "Next" \
            --msgbox "${remote_message}" $HEIGHT $WIDTH
        check_response $?

        dialog \
            --backtitle "OpenFLIXR Setup" \
            --title "Step ${step_number}: ${step_name} - Remote" \
            --clear \
            --ok-button "Next" \
            --msgbox "Forward ports 80 and 443 on your router to your local IP (${LOCAL_IP})" $HEIGHT $WIDTH
        check_response $?
    fi
}
