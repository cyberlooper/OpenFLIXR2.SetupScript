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
        sudo updateopenflixr
    elif [[ ${config[PRECHECK_UPGRADE]:-} == "COMPLETED" && ${config[PRECHECK_CLEANUP]:-} != "COMPLETED" ]]; then
        run_script 'fixes_mono'
        info "Cleaning up some things..."
        rm "/etc/sudoers.d/firstrun"
        sed -i 's#echo "Running precheck script"##g' "${DETECTED_HOMEDIR}/.bashrc"
        sed -i 's#bash precheck.sh##g' "${DETECTED_HOMEDIR}/.bashrc"
        sed -i 's#bash -c "$(curl -fsSL https://raw.githubusercontent.com/openflixr/Docs/.*/precheck.sh)"##g' "${DETECTED_HOMEDIR}/.bashrc"
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
        fi
    elif [[ ${config[PRECHECK_UPGRADE]:-} == "COMPLETED" && ${config[PRECHECK_CLEANUP]:-} == "COMPLETED" ]]; then
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
        fi
    else
        error "... Well, this is unexpected..."
    fi
}