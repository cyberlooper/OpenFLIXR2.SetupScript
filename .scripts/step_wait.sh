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
    local elapsed_minutes
    elapsed_minutes="none"
    local WAIT_STATUS
    WAIT_STATUS=0
    { # For whiptail
        local LOG_LINE
        LOG_LINE=""
        local start
        start=$(date +%s)

        while true; do
            local elapsed
            local percent
            elapsed=$(($(date +%s)-$start))
            duration=$(date -ud @$elapsed +'%M minutes %S seconds')
            percent=$(($elapsed/10))

            UPDATEOF_LOG_LINE=$(tail -1 $UPDATEOF_LOGFILE)
            ONLINEUPDATE_LOG_LINE=$(tail -1 $ONLINEUPDATE_LOGFILE)
            if [[ -f "/opt/OpenFLIXR2.SetupScript/stop_wait" ]]; then
                echo -e "XXX\n100\Skipping wait!\nXXX"
                break
            elif [[ "$UPDATEOF_LOG_LINE" = "updateof finished"
                    || "$ONLINEUPDATE_LOG_LINE" = "onlineupdate finished" ]]; then
                echo -e "XXX\n100\nDone!\nXXX"
                break
            fi

            elapsed_minutes=$(date -ud @$elapsed +%M)
            if [[ ${elapsed_minutes#0} -ge 16 ]]; then
                echo -e "XXX\n100\Failure!\nXXX"
                break
            else
                echo -e "XXX\n$percent\nDuration: $duration\nXXX"
            fi

            sleep 5s
        done
    } | whiptail --title "Step ${step_number}: Checking to make sure OpenFLIXR is ready." --gauge "This may take about 15 minutes depending on when you ran this script..." 10 75 0

    UPDATEOF_LOG_LINE=$(tail -1 $UPDATEOF_LOGFILE)
    ONLINEUPDATE_LOG_LINE=$(tail -1 $ONLINEUPDATE_LOGFILE)
    if [[ -f "/opt/OpenFLIXR2.SetupScript/stop_wait" ]]; then
        waring "Found stop_wait file. Skipping the wait step."
        info "Removing stop_wait file"
        rm "/opt/OpenFLIXR2.SetupScript/stop_wait" || warning "Could not remove stop_wait file. Please remove manually: /opt/OpenFLIXR2.SetupScript/stop_wait"
    elif [[ "$UPDATEOF_LOG_LINE" = "updateof finished" ]]; then
        info "Found 'updateof finished' in $UPDATEOF_LOGFILE"
    elif [[ "$ONLINEUPDATE_LOG_LINE" = "onlineupdate finished" ]]; then
        info "Found 'onlineupdate finished' in $ONLINEUPDATE_LOGFILE"
    else
        warning "Failed to find redy flags after ${duration}."
        info "OpenFLIXR updateof log file (last 5 lines)"
        tail -5 $UPDATEOF_LOGFILE
        tail -5 $UPDATEOF_LOGFILE  >> $LOG_FILE
        info "OpenFLIXR onlineupdate log file (last 5 lines)"
        tail -5 $ONLINEUPDATE_LOGFILE
        tail -5 $ONLINEUPDATE_LOGFILE  >> $LOG_FILE
        fatal "Exiting OpenFLIXR Setup"
        exit 1
    fi
}
