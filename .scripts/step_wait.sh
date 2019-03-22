#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

step_wait() {
    local UPDATEOF_LOGFILE
    UPDATEOF_LOGFILE="/var/log/updateof.log"
    local ONLINEUPDATE_LOGFILE
    ONLINEUPDATE_LOGFILE="/var/log/openflixrupdate/onlineupdate.log"
    local duration
    duration=""
    local WAIT_STATUS
    WAIT_STATUS=0
    { # For whiptail
        local LOG_LINE
        LOG_LINE=""
        local start
        start=$(date +%s)
        echo "${start}" >> $LOG_FILE

        while true; do
            local elapsed
            local percent
            elapsed=$(($(date +%s)-$start))
            duration=$(date -ud @$elapsed +'%M minutes %S seconds')
            percent=$(($elapsed/10))

            if [[ -f "/opt/OpenFLIXR2.SetupScript/stop_wait" ]]; then
                WAIT_STATUS=1
                break
            fi

            LOG_LINE=$(tail -1 $UPDATEOF_LOGFILE)
            if [[ "$LOG_LINE" = "updateof finished" ]]; then
                WAIT_STATUS=2
                break
            fi

            LOG_LINE=$(tail -1 $ONLINEUPDATE_LOGFILE)
            if [[ "$LOG_LINE" = "onlineupdate finished" ]]; then
                WAIT_STATUS=3
                break
            fi

            local elapsed_minutes=$(date -ud @$elapsed +%M)
            if [[ ${elapsed_minutes#0} -ge 16 ]]; then
                WAIT_STATUS=0
                break
            else
                echo -e "XXX\n$percent\nDuration: $duration\nXXX"
            fi

            sleep 5s
        done

        if [[ $WAIT_STATUS = 1 ]]; then
            echo -e "XXX\n100\nDone!\nXXX"
        else
            echo -e "XXX\n100\Failure!\nXXX"
        fi
    } | whiptail --title "Step ${step_number}: Checking to make sure OpenFLIXR is ready." --gauge "This may take about 15 minutes depending on when you ran this script..." 10 75 0

    info "Waited for ${duration}"
    if [[ $WAIT_STATUS = 1 ]]; then
        info "Found stop_wait file"
        info "Removing stop_wait file"
        rm "/opt/OpenFLIXR2.SetupScript/stop_wait" || fatal "Could not remove stop_wait file. Please remove manually: /opt/OpenFLIXR2.SetupScript/stop_wait"
        exit 1
    elif [[ $WAIT_STATUS = 2 ]]; then
        info "Found 'updateof finished' in $UPDATEOF_LOGFILE"
    elif [[ $WAIT_STATUS = 3 ]]; then
        info "Found 'onlineupdate finished' in $ONLINEUPDATE_LOGFILE"
    else
        warning "Failed to find redy flags after ${duration}."
        info "OpenFLIXR updateof log file (last 5 lines)"
        tail -5 $UPDATEOF_LOGFILE  >> $LOG_FILE
        info "OpenFLIXR onlineupdate log file (last 5 lines)"
        tail -5 $ONLINEUPDATE_LOGFILE  >> $LOG_FILE
        fatal "Exiting OpenFLIXR Setup"
        exit 1
    fi
}
