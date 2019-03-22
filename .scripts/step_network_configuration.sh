#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

step_network_configuration() {
    done=0
    while [[ ! $done = 1 ]]; do
        networkconfig=$(whiptail --radiolist --title "Step ${step_number}: ${step_name}" "Choose network configuration" 0 0 9 \
                        dhcp "DHCP" on \
                        static "Static IP" off 3>&1 1>&2 2>&3)
        run_script 'check_response' $?;
        set_config "NETWORK" $networkconfig

        if [[ $networkconfig = 'static' ]]; then
            info "Configuring for Static IP"

            valid=0
            while [[ ! $valid = 1 ]]; do
                ip=$(whiptail --inputbox --title "Step ${step_number}: ${step_name}" "IP Address" 0 0 3>&1 1>&2 2>&3)
                run_script 'check_response' $?;

                valid_ip=run_script 'validate_ip' $ip
                if $valid_ip; then
                    info "IP Address: ${ip}"
                    set_config "OPENFLIXR_IP" $ip
                    valid=1
                else
                    warning "Invalid IP Address: ${ip}"
                    whiptail --title "Step ${step_number}: ${step_name}" --ok-button "Try Again" --msgbox "Invalid IP Address" 0 0
                fi
            done

            valid=0
            while [[ ! $valid = 1 ]]; do
                subnet=$(whiptail --inputbox --title "Step ${step_number}: ${step_name}" "Subnet Mask" 0 0 3>&1 1>&2 2>&3)
                run_script 'check_response' $?;

                valid_ip=$(run_script 'validate_ip' ${ip})
                if $valid_ip; then
                    set_config "OPENFLIXR_SUBNET" $subnet
                    valid=1
                else
                    whiptail --title "Step ${step_number}: ${step_name}" --ok-button "Try Again" --msgbox "Invalid IP Address" 0 0
                fi
            done

            valid=0
            while [[ ! $valid = 1 ]]; do
                gateway=$(whiptail --inputbox --title "Step ${step_number}: ${step_name}" "Gateway" 0 0 3>&1 1>&2 2>&3)
                run_script 'check_response' $?;

                valid_ip=$(run_script 'validate_ip' ${ip})
                if $valid_ip; then
                    set_config "OPENFLIXR_GATEWAY" $gateway
                    valid=1
                else
                    whiptail --title "Step ${step_number}: ${step_name}" --ok-button "Try Again" --msgbox "Invalid IP Address" 0 0
                fi
            done

            done=1
        fi

        if [[ $networkconfig = 'dhcp' ]]; then
            info "Configuring for DHCP"
            done=1
        fi

        if [[ $networkconfig = '' ]]; then
            whiptail --title "Step ${step_number}: ${step_name}" --yes-button "Try Again" --no-button "Cancel" --yesno "Something went wrong getting Network Configuration settings... Try again or select cancel to quit" 0 0
            run_script 'check_response' $?;
        fi
    done
}
