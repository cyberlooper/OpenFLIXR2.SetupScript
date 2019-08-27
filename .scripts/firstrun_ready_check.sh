#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

firstrun_ready_check()
{
    run_script 'load_config'
    if [[ ${config[FIRSTRUN_READY]:-} != "COMPLETED" ]]; then
        if [[ ${config[FIRSTRUN_UPTIME]:-} == "COMPLETED" && ${config[FIRSTRUN_PROCESSCHECK]:-} == "COMPLETED" && ${config[FIRSTRUN_DNSCHECK]:-} == "COMPLETED" ]]; then
            run_script 'set_config' "FIRSTRUN_READY" "COMPLETED"
            info "|------------------------------------------------|"
            info "| OpenFLIXR is PROBABLY ready for upgrade!       |"
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
        info "| OpenFLIXR is PROBABLY ready for for upgrade!   |"
        info "|------------------------------------------------|"
    fi
}