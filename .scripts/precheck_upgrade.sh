#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

precheck_upgrade()
{
    run_script 'load_config'
    if [[ ${UBU_VER} == "18.04" && ${config[PRECHECK_UPGRADE]:-} != "COMPLETED" ]]; then
        run_script 'set_config' "PRECHECK_UPGRADE" "COMPLETED"
        info "System upgraded successfully!"
    fi
    if [[ ${config[PRECHECK_UPGRADE]:-} != "COMPLETED" && ${config[PRECHECK_PREPARE_UPGRADE]:-} == "COMPLETED" ]]; then
        info "Upgrading the system. Please be patient, this can take a while..."
        sleep 5s
        updateopenflixr
    elif [[ ${config[PRECHECK_UPGRADE]:-} == "COMPLETED" && ${config[PRECHECK_FIXES]:-} != "COMPLETED" ]]; then
        info "Running some final fixes"
        run_script 'fixes_mono'
        run_script 'fixes_sonarr'
        run_script 'fixes_pihole'
        run_script 'fixes_kernel'
        run_script 'set_config' "PRECHECK_FIXES" "COMPLETED"
        reboot
    elif [[ ${config[PRECHECK_UPGRADE]:-} == "COMPLETED" && ${config[PRECHECK_FIXES]:-} == "COMPLETED" && ${config[PRECHECK_CLEANUP]:-} != "COMPLETED" ]]; then
        info "Cleaning up some things..."
        rm "/etc/sudoers.d/firstrun"
        sed -i 's/.*#firstrun-startup//g' "${DETECTED_HOMEDIR}/.bashrc"
        run_script 'set_config' "PRECHECK_CLEANUP" "COMPLETED"
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
    elif [[ ${config[PRECHECK_UPGRADE]:-} == "COMPLETED" && ${config[PRECHECK_CLEANUP]:-} == "COMPLETED" ]]; then
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