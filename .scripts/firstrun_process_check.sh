#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

firstrun_process_check()
{
    run_script 'load_config'
    local start=$(date +%s)
    local start_display=$(date)
    local duration=""
    local elapsed_minutes="none"
    local APT_COUNT_LAST=0
    local APT_COUNT_LAST_ELAPSED_MINUTES=0
    local UPDATE_COUNT_LAST=0
    local UPDATE_COUNT_LAST_ELAPSED_MINUTES=0
    local UPGRADE_COUNT_LAST=0
    local UPGRADE_COUNT_LAST_ELAPSED_MINUTES=0
    local WAIT_TIME=5
    if [[ ${config[FIRSTRUN_PROCESSCHECK]:-} != "COMPLETED" ]]; then
        info "Waiting for the system to finish some processes..."
        while (true); do
            clear
            elapsed=$(($(date +%s)-$start))
            duration=$(date -ud @$elapsed +'%M minutes %S seconds')
            echo ""
            echo "Waiting for the system to finish some processes..."
            echo "Started: ${start_display}"
            echo "Now:     $(date)"
            echo "Elapsed: ${duration}"
            APT_COUNT=$(ps -ef | grep apt | grep -v tail | grep -v grep | wc -l || true)
            echo " - Apt processes remaining: ${APT_COUNT}"
            if [[ ${APT_COUNT} != 0 && ${APT_COUNT_LAST_ELAPSED:-} != "" ]]; then
                echo "   Last changed: $(date -ud @${APT_COUNT_LAST_ELAPSED} +'%M minutes %S seconds')"
            else
                echo ""
            fi

            UPDATE_COUNT=$(ps -ef | grep update | grep -v "no-update" | grep -v tail | grep -v shellinabox | grep -v grep | wc -l || true)
            echo " - Update processes remaining: ${UPDATE_COUNT}"
            if [[ ${UPDATE_COUNT} != 0 && ${UPDATE_COUNT_LAST_ELAPSED:-} != "" ]]; then
                echo "   Last changed: $(date -ud @${UPDATE_COUNT_LAST_ELAPSED} +'%M minutes %S seconds')"
            else
                echo ""
            fi

            UPGRADE_COUNT=$(ps -ef | grep upgrade | grep -v tail | grep -v shellinabox | grep -v unattended-upgrade | grep -v FirstRun | grep -v grep | wc -l || true)
            echo " - Upgrade processes remaining: ${UPGRADE_COUNT}"
            if [[ ${UPGRADE_COUNT} != 0 && ${UPGRADE_COUNT_LAST_ELAPSED:-} != "" ]]; then
                echo "   Last changed: $(date -ud @${UPGRADE_COUNT_LAST_ELAPSED} +'%M minutes %S seconds')"
            else
                echo ""
            fi

            if [[ ${APT_COUNT} = 0 && ${UPDATE_COUNT} = 0 && ${UPGRADE_COUNT} = 0 ]]; then
                run_script 'set_config' "FIRSTRUN_PROCESSCHECK" "COMPLETED"
                info "- Completed!"
                log "  Elapsed: ${duration}"
                break
            elif [[ ${APT_COUNT_LAST_ELAPSED_MINUTES#0} -ge ${WAIT_TIME} && ${UPDATE_COUNT} -eq 0 && ${UPGRADE_COUNT} -eq 0 ]]; then
                local WAIT_MULTIPLIER=$((${APT_COUNT_LAST_ELAPSED_MINUTES#0}/${WAIT_TIME}))
                local CURRENT_WAIT_TIME=$((${WAIT_TIME}*${WAIT_MULTIPLIER}))
                echo "> It has been more than ${CURRENT_WAIT_TIME} minutes since APT has changed and no updates or upgrades are running."
                echo "> This is okay. Just. Keep. Waiting."
            else
                echo "> Keep waiting..."
            fi

            if [[ ${APT_COUNT} != ${APT_COUNT_LAST} ]]; then
                APT_COUNT_LAST=${APT_COUNT}
                APT_COUNT_CHANGED=$(date +%s)
            elif [[ ${APT_COUNT} == 0 ]]; then
                APT_COUNT_CHANGED=""
            fi
            if [[ ${APT_COUNT_CHANGED:-} != "" ]]; then
                APT_COUNT_LAST_ELAPSED=$(($(date +%s)-${APT_COUNT_CHANGED}))
                APT_COUNT_LAST_ELAPSED_MINUTES=$(date -ud @${APT_COUNT_LAST_ELAPSED} +%M)
            fi

            if [[ ${UPDATE_COUNT} != ${UPDATE_COUNT_LAST} ]]; then
                UPDATE_COUNT_LAST=${UPDATE_COUNT}
                UPDATE_COUNT_CHANGED=$(date +%s)
            elif [[ ${UPDATE_COUNT} == 0 ]]; then
                UPDATE_COUNT_CHANGED=""
            fi
            if [[ ${UPDATE_COUNT_CHANGED:-} != "" ]]; then
                UPDATE_COUNT_LAST_ELAPSED=$(($(date +%s)-${UPDATE_COUNT_CHANGED}))
                UPDATE_COUNT_LAST_ELAPSED_MINUTES=$(date -ud @${UPDATE_COUNT_LAST_ELAPSED} +%M)
            fi

            if [[ ${UPGRADE_COUNT} != ${UPGRADE_COUNT_LAST} ]]; then
                UPGRADE_COUNT_LAST=${UPGRADE_COUNT}
                UPGRADE_COUNT_CHANGED=$(date +%s)
            elif [[ ${UPGRADE_COUNT} == 0 ]]; then
                UPGRADE_COUNT_CHANGED=""
            fi
            if [[ ${UPGRADE_COUNT_CHANGED:-} != "" ]]; then
                UPGRADE_COUNT_LAST_ELAPSED=$(($(date +%s)-${UPGRADE_COUNT_CHANGED}))
                UPGRADE_COUNT_LAST_ELAPSED_MINUTES=$(date -ud @${UPGRADE_COUNT_LAST_ELAPSED} +%M)
            fi

            sleep 5;
        done
    else
        info "Process check already completed!"
    fi
}