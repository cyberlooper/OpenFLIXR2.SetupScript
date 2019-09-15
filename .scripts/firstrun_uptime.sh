#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

firstrun_uptime()
{
    run_script 'load_config'
    local WAIT_UPTIME=10
    if [[ ${config[FIRSTRUN_UPTIME]:-} != "COMPLETED" ]]; then
        echo ""
        info "Waiting for the system to have been running for ${WAIT_UPTIME} minutes"
        while (true); do
            UPTIME_HOURS=$(awk '{print int($1/3600)}' /proc/uptime)
            UPTIME_MINUTES=$(awk '{print int(($1%3600)/60)}' /proc/uptime)
            UPTIME_SECONDS=$(awk '{print int($1%60)}' /proc/uptime)
            if [[ ${UPTIME_HOURS} -gt 0 || ${UPTIME_MINUTES} -ge ${WAIT_UPTIME} ]]; then
                run_script 'set_config' "FIRSTRUN_UPTIME" "COMPLETED"
                echo ""
                info "- Wait complete!"
                break
            else
                echo -en "\rCurrent Uptime: ${UPTIME_HOURS} hours ${UPTIME_MINUTES} minutes ${UPTIME_SECONDS} seconds    "
            fi
            sleep 5s
        done
    else
        info "System uptime check already completed!"
    fi
}