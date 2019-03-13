#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

step_wait() {
    {
        local OPENFLIXR_LOGFILE
        OPENFLIXR_LOGFILE="/var/log/updateof.log"
        local UPDATEOF_LINE
        UPDATEOF_LINE=""
        local start
        start=$(date +%s)
        while [[ ! $UPDATEOF_LINE = "updateof finished" ]]; do
            local elapsed
            elapsed=$(($(date +%s)-$start))
            local duration
            duration=$(date -ud @$elapsed +'%M minutes %S seconds')
            local percent
            percent=$(($elapsed/10))

            UPDATEOF_LINE=$(tail -1 $OPENFLIXR_LOGFILE)

            if [[ $UPDATEOF_LINE = "updateof finished" ]]; then
                info "Found 'updateof finished' in $OPENFLIXR_LOGFILE"
                info "Waited for ${duration}"
                break
            fi
            sleep 5s

            if [[ $(date -ud @$elapsed +%M) -ge 16 ]]; then
                echo -e "XXX\n100\Failure!\nXXX"
                warning "Failed to detect completion of the OpenFLIXR box after ${duration}."
                info "OpenFLIXR log file (last 5 lines)"
                tail -5 $OPENFLIXR_LOGFILE  >> $LOG_FILE
                info "OpenFLIXR Setup tmp file"
                cat $OPENFLIXR_SETUP_PATH"/tmp.log"
                fatal "Exiting OpenFLIXR Setup"
                exit 1
            else
                echo -e "XXX\n$percent\nDuration: $duration\nXXX"
            fi
        done
        echo -e "XXX\n100\nDone!\nXXX"
    } | whiptail --title "Step ${step_number}: Checking to make sure OpenFLIXR is ready." --gauge "This may take about 15 minutes depending on when you ran this script..." 10 75 0

}
