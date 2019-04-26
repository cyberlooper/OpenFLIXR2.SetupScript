#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

step_network_configuration() {
    local STEP_TITLE=${1:-"Step ${step_number}: ${step_name}"}
    local NETWORKOPTS=()
    NETWORKOPTS+=("DHCP " "")
    NETWORKOPTS+=("Static " "")

    local CONFIGCHOICE
    if [[ ${CI:-} == true ]] && [[ ${TRAVIS:-} == true ]]; then
        CONFIGCHOICE="Cancel"
    else
        CONFIGCHOICE=$(whiptail \
                        --backtitle ${OF_BACKTITLE} \
                        --title "${STEP_TITLE}" \
                        --menu "Choose network configuration type" \
                        0 0 0 "${NETWORKOPTS[@]}" \
                        3>&1 1>&2 2>&3 || echo "Cancel")
    fi
    run_script 'check_response' $?

    done=0
    while [[ ! $done = 1 ]]; do
        case "${CONFIGCHOICE}" in
            "Static ")
                set_config "NETWORK" "static"
                info "Configuring for Static IP"

                valid=0
                while [[ ! $valid = 1 ]]; do
                    ip=$(whiptail --inputbox --title "${STEP_TITLE} - Static" "IP Address" 0 0 ${config[OPENFLIXR_IP]} 3>&1 1>&2 2>&3)
                    run_script 'check_response' $?;

                    valid_ip=$(run_script 'validate_ip' $ip)
                    if $valid_ip; then
                        info "IP Address: ${ip}"
                        set_config "OPENFLIXR_IP" $ip
                        valid=1
                    else
                        warning "Invalid IP Address: ${ip}"
                        whiptail --title "${STEP_TITLE}" --ok-button "Try Again" --msgbox "Invalid IP Address" 0 0
                    fi
                done

                valid=0
                while [[ ! $valid = 1 ]]; do
                    subnet=$(whiptail --inputbox --title "${STEP_TITLE} - Static" "Subnet Mask" 0 0 ${config[OPENFLIXR_SUBNET]} 3>&1 1>&2 2>&3)
                    run_script 'check_response' $?;

                    valid_ip=$(run_script 'validate_ip' ${ip})
                    if $valid_ip; then
                        set_config "OPENFLIXR_SUBNET" $subnet
                        valid=1
                    else
                        whiptail --title "${STEP_TITLE}" --ok-button "Try Again" --msgbox "Invalid IP Address" 0 0
                    fi
                done

                valid=0
                while [[ ! $valid = 1 ]]; do
                    gateway=$(whiptail --inputbox --title "${STEP_TITLE} - Static" "Gateway" 0 0 ${config[OPENFLIXR_GATEWAY]} 3>&1 1>&2 2>&3)
                    run_script 'check_response' $?;

                    valid_ip=$(run_script 'validate_ip' ${ip})
                    if $valid_ip; then
                        set_config "OPENFLIXR_GATEWAY" $gateway
                        valid=1
                    else
                        whiptail --title "${STEP_TITLE}" --ok-button "Try Again" --msgbox "Invalid IP Address" 0 0
                    fi
                done

                done=1
                ;;
            "DHCP ")
                info "Configuring for DHCP"
                set_config "NETWORK" "dhcp"
                set_config "OPENFLIXR_IP" ${LOCAL_IP}
                done=1
                ;;
            *)
                whiptail --title "${STEP_TITLE}" --yes-button "Try Again" --no-button "Cancel" --yesno "Something went wrong getting Network Configuration settings... Try again or select cancel to quit" 0 0
                run_script 'check_response' $?;
                ;;
        esac
    done
}
