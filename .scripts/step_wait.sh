#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

step_wait() {
    if [[ ! -v DEVMODE ]]; then
        readonly WAIT_TIME=16
    else
        readonly WAIT_TIME=1
    fi
    local UPDATEOF_LOGFILE
    UPDATEOF_LOGFILE="/var/log/updateof.log"
    local ONLINEUPDATE_LOGFILE
    ONLINEUPDATE_LOGFILE="/var/log/openflixrupdate/onlineupdate.log"
    local duration
    duration=""
    local elapsed_minutes
    elapsed_minutes="none"
    local LOG_LINE
    LOG_LINE=""
    local start
    start=$(date +%s)
    local elapsed
    local percent
    local UPDATEOF_LOG_LINE
    local ONLINEUPDATE_LOG_LINE
    local OF_VERSION_FULL
    local OF_VERSION_MAJOR
    local OF_VERSION_MINOR
    local OF_VERSION_WEB
    local OF_VERSION_WEB_MAJOR
    local OF_VERSION_WEB_MINOR
    local OF_UPDATE_PS
    local OF_UPDATE_PS_FULL

    debug "OPENFLIXR_READY='${config[OPENFLIXR_READY]}'"
    if [[ "${config[OPENFLIXR_READY]}" != "YES" ]]; then
        info "Waiting for OpenFLIXR to be ready..."
        while true; do
            elapsed=$(($(date +%s)-$start))
            duration=$(date -ud @$elapsed +'%M minutes %S seconds')
            percent=$(($elapsed/10))

            log "Checking updateof"
            UPDATEOF_LOG_LINE=$(tail -1 $UPDATEOF_LOGFILE)
            log "Checking onlineupdate"
            ONLINEUPDATE_LOG_LINE=$(tail -1 $ONLINEUPDATE_LOGFILE)
            log "Getting OpenFLIXR version"
            OF_VERSION_FULL=$(grep -o "^[0-9]\.[0-9]\.[0-9]" /opt/openflixr/version)
            OF_VERSION_MAJOR=$(cut -d'.' -f1 <<< $OF_VERSION_FULL)
            OF_VERSION_MINOR=$(cut -d'.' -f2 <<< $OF_VERSION_FULL)
            log "Getting OpenFLIXR web version"
            OF_VERSION_WEB=$(crudini --get /usr/share/nginx/html/setup/config.ini custom custom1)
            OF_VERSION_WEB_MAJOR=$(cut -d'.' -f1 <<< $OF_VERSION_FULL)
            OF_VERSION_WEB_MINOR=$(cut -d'.' -f2 <<< $OF_VERSION_FULL)
            log "Getting any running 'update' proceses"
            OF_UPDATE_PS=$(echo $(ps -ef | grep -i update | grep -v grep | grep -v shellinabox | grep -v tail | cut -c1-5))
            OF_UPDATE_PS_FULL=$(echo $(ps -ef | grep -i update | grep -v grep | grep -v shellinabox | grep -v tail))
            log "Performing checks"
            if [[ -f "/opt/OpenFLIXR2.SetupScript/stop_wait" ]]; then
                echo -e "XXX\n100\Skipping wait!\nXXX"
                WAIT_STATUS=1
                break
            elif [[ "$UPDATEOF_LOG_LINE" = "updateof finished" ]]; then
                echo -e "XXX\n100\nDone!\nXXX"
                WAIT_STATUS=4
                break
            elif [[ "$ONLINEUPDATE_LOG_LINE" = "onlineupdate finished" ]]; then
                echo -e "XXX\n100\nDone!\nXXX"
                WAIT_STATUS=5
                break
            elif [[ "${OF_VERSION_FULL}" == "${OF_VERSION_WEB}"
                    && $(echo "${OF_VERSION_MAJOR}.${OF_VERSION_MINOR} >= 2.9" | bc -l) = 1
                    && $(echo "${OF_VERSION_WEB_MAJOR}.${OF_VERSION_WEB_MINOR} >= 2.9" | bc -l) = 1
                    && "${OF_UPDATE_PS}" == "" ]]; then
                echo -e "XXX\n100\nDone!\nXXX"
                WAIT_STATUS=8
                break
            fi

            elapsed_minutes=$(date -ud @$elapsed +%M)
            log "Elapsed: ${elapsed_minutes}"
            if [[ ${elapsed_minutes#0} -ge ${WAIT_TIME} ]]; then
                echo -e "XXX\n100\Failure!\nXXX"
                WAIT_STATUS=0
                break
            else
                echo -e "XXX\n$percent\nDuration: $duration\nXXX"
            fi

            sleep 5s
        done > >(whiptail --title "Step ${step_number}: Checking to make sure OpenFLIXR is ready." --gauge "This may take about 15 minutes depending on when you ran this script..." 10 75 0)

        case $WAIT_STATUS in
            1)
                warning "Found stop_wait file. Skipping the wait step."
                info "Removing stop_wait file"
                rm "/opt/OpenFLIXR2.SetupScript/stop_wait" || warning "Could not remove stop_wait file. Please remove manually: /opt/OpenFLIXR2.SetupScript/stop_wait"
                ;;
            4)
                info "Found 'updateof finished' in $UPDATEOF_LOGFILE"
                ;;
            5)
                info "Found 'onlineupdate finished' in $ONLINEUPDATE_LOGFILE"
                ;;
            8)
                info "OpenFLIXR versions match and no update process is running!"
                ;;
            *)
                warning "Failed to find ready flags after ${duration} or WAIT_STATUS not properly set..."
                info "Saving debug information to log..."
                log "OpenFLIXR version: ${OF_VERSION_FULL}"
                log "OpenFLIXR Web version: ${OF_VERSION_WEB}"
                log "WAIT_STATUS: ${WAIT_STATUS}"
                log "OpenFLIXR updateof log file (last 5 lines)"
                tail -5 $UPDATEOF_LOGFILE >> $LOG_FILE
                log "OpenFLIXR onlineupdate log file (last 5 lines)"
                tail -5 $ONLINEUPDATE_LOGFILE >> $LOG_FILE
                log "OpenFLIXR update processes"
                echo $OF_UPDATE_PS_FULL >> $LOG_FILE
                fatal "Aborting OpenFLIXR Setup"
                exit 1
                ;;
        esac

        run_script 'set_config' "OPENFLIXR_READY" "YES"
    fi

    info "OpenFLIXR Ready"
}
