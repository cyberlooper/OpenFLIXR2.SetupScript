#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

firstrun_upgrade()
{
    run_script 'load_config'
    if [[ ${UBU_VER} == "18.04" && ${config[FIRSTRUN_UPGRADE]:-} != "COMPLETED" ]]; then
        run_script 'set_config' "FIRSTRUN_UPGRADE" "COMPLETED"
        info "System upgraded successfully!"
    fi
    if [[ ${config[FIRSTRUN_UPGRADE]:-} != "COMPLETED" && ${config[FIRSTRUN_PREPARE_UPGRADE]:-} == "COMPLETED" ]]; then
        info "Upgrading the system. Please be patient, this can take a while..."
        sleep 5s
        updateopenflixr
    elif [[ ${config[FIRSTRUN_UPGRADE]:-} == "COMPLETED" && ${config[FIRSTRUN_FIXES]:-} != "COMPLETED" ]]; then
        info "Running some final fixes"
        run_script 'fixes_mono'
        run_script 'fixes_sonarr'
        run_script 'fixes_pihole'
        run_script 'fixes_kernel'
        run_script 'fixes_ubooquity'
        run_script 'set_config' "FIRSTRUN_FIXES" "COMPLETED"
        reboot
    elif [[ ${config[FIRSTRUN_UPGRADE]:-} == "COMPLETED" && ${config[FIRSTRUN_FIXES]:-} == "COMPLETED" && ${config[FIRSTRUN_CLEANUP]:-} != "COMPLETED" ]]; then
        info "Cleaning up some things..."
        rm "/etc/sudoers.d/firstrun"
        rm "/etc/systemd/system/getty@tty1.service.d/override.conf"
        sed -i 's/.*#firstrun-startup//g' "${DETECTED_HOMEDIR}/.bashrc"
        run_script 'set_config' "FIRSTRUN_CLEANUP" "COMPLETED"
        info "|------------------------------------------------|"
        info "| OpenFLIXR should now be ready for use!!        |"
        info "|------------------------------------------------|"
        if [[ $(grep -c "#openflixr-ready" "${DETECTED_HOMEDIR}/.profile") == 0 ]]; then
            info "Adding OpenFLIXR Ready Banner to .profile"
            echo "" >> "${DETECTED_HOMEDIR}/.profile"
            echo "echo '|------------------------------------------------|' #openflixr-ready" >> "${DETECTED_HOMEDIR}/.profile"
            echo "echo '| OpenFLIXR should now be ready for use!!        |' #openflixr-ready" >> "${DETECTED_HOMEDIR}/.profile"
            echo "echo '|------------------------------------------------|' #openflixr-ready" >> "${DETECTED_HOMEDIR}/.profile"
            echo "sed -i 's/.*#openflixr-ready//g' '${DETECTED_HOMEDIR}/.profile' #openflixr-ready" >> "${DETECTED_HOMEDIR}/.profile"
            info "- Done"
            reboot
        fi
    elif [[ ${config[FIRSTRUN_UPGRADE]:-} == "COMPLETED" && ${config[FIRSTRUN_CLEANUP]:-} == "COMPLETED" ]]; then
        info "|------------------------------------------------|"
        info "| OpenFLIXR should now be ready for use!!        |"
        info "|------------------------------------------------|"
        if [[ $(grep -c "#openflixr-ready" "${DETECTED_HOMEDIR}/.profile") != 0 ]]; then
            sed -i 's/.*#openflixr-ready//g' '${DETECTED_HOMEDIR}/.profile'
        fi
        if [[ $(grep -c "#firstrun-startup" "${DETECTED_HOMEDIR}/.profile") != 0 ]]; then
            sed -i 's/.*#firstrun-startup//g' "${DETECTED_HOMEDIR}/.bashrc"
        fi
    else
        error "... Well, this is unexpected..."
    fi
}