#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

precheck_ready_check()
{
    run_script 'load_config'
    if [[ ${config[PRECHECK_FIXES]:-} != "COMPLETED" ]]; then
        if [[ ${config[PRECHECK_UPTIME]:-} == "COMPLETED" && ${config[PRECHECK_PROCESSCHECK]:-} == "COMPLETED" && ${config[PRECHECK_DNSCHECK]:-} == "COMPLETED" ]]; then
            run_script 'set_config' "PRECHECK_FIXES" "COMPLETED"
            info "|------------------------------------------------|"
            info "| OpenFLIXR is PROBABLY ready for the next step! |"
            info "|------------------------------------------------|"
            echo ""
        else
            warning "> Something went wrong and you probably shouldn't continue... "
            warning "> Check the wiki for troubleshooting information."
            warning "> If further help is needed, join OpenFLIXR's Discord Server or post on the forums for assistance"
            exit 255
        fi
    else
        info "|------------------------------------------------|"
        info "| OpenFLIXR is PROBABLY ready for the next step! |"
        info "|------------------------------------------------|"
    fi
}