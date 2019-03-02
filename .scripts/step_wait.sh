#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

step_wait() {
    {
        local OPENFLIXR_LOGFILE
        OPENFLIXR_LOGFILE="/var/log/updateof.log"
        local LOG_LINE
        LOG_LINE=""
        local start
        start=$(date +%s)
        while [[ ! $LOG_LINE = "Set Version" ]]; do
            tail -5 $OPENFLIXR_LOGFILE > "${SCRIPTPATH}/tmp.log"
            while IFS='' read -r line || [[ -n "$line" ]]; do
                LOG_LINE="$line"

                if [[ $LOG_LINE = "Set Version" ]]; then
                    info "Found 'Set Version' in $OPENFLIXR_LOGFILE"
                    break
                fi
            done < "${SCRIPTPATH}/tmp.log"
            sleep 5s

            local elapsed
            elapsed=$(($(date +%s)-$start))
            local duration
            duration=$(date -ud @$elapsed +'%M minutes %S seconds')
            local percent
            percent=$(($elapsed/10))

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
        rm "${SCRIPTPATH}/tmp.log"
        echo -e "XXX\n100\nDone!\nXXX"
    } | whiptail --title "Step ${step_number}: Checking to make sure OpenFLIXR is ready." --gauge "This may take about 15 minutes depending on when you ran this script..." 10 75 0

}
