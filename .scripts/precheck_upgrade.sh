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
        rm "/etc/sudoers.d/precheck"
        sed -i 's#echo "Running precheck script"##g' "${DETECTED_HOMEDIR}/.bashrc"
        sed -i 's#bash precheck.sh##g' "${DETECTED_HOMEDIR}/.bashrc"
        sed -i 's#bash -c "$(curl -fsSL https://raw.githubusercontent.com/openflixr/Docs/.*/precheck.sh)"##g' "${DETECTED_HOMEDIR}/.bashrc"
        sed -i 's/.*#firstrun-startup//g' "${DETECTED_HOMEDIR}/.bashrc"
        run_script 'set_config' "PRECHECK_CLEANUP" "COMPLETED"
        info "|------------------------------------------------|"
        info "| OpenFLIXR should now be ready for use!!        |"
        info "|------------------------------------------------|"
    elif [[ ${config[PRECHECK_UPGRADE]:-} == "COMPLETED" && ${config[PRECHECK_CLEANUP]:-} == "COMPLETED" ]]; then
        info "|------------------------------------------------|"
        info "| OpenFLIXR should now be ready for use!!        |"
        info "|------------------------------------------------|"
    else
        error "... Well, this is unexpected..."
    fi
}