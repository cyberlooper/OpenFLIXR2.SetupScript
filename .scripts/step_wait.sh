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
    local WAIT_STATUS
    local WAIT_STATUS_HOLD
    local ERROR_MSG

    debug "OPENFLIXR_READY='${config[OPENFLIXR_READY]}'"
    if [[ "${config[OPENFLIXR_READY]}" != "YES" ]]; then
        info "Waiting for OpenFLIXR to be ready..."
        while true; do
            elapsed=$(($(date +%s)-$start))
            duration=$(date -ud @$elapsed +'%M minutes %S seconds')
            percent=$(($elapsed/10))

            log "Checking updateof"
            UPDATEOF_LOG_LINE=$(tail -1 $UPDATEOF_LOGFILE 2>> $LOG_FILE || echo "FAIL")
            log "Checking onlineupdate"
            ONLINEUPDATE_LOG_LINE=$(tail -1 $ONLINEUPDATE_LOGFILE 2>> $LOG_FILE || echo "FAIL")
            log "Getting OpenFLIXR version"
            if [[ -f "/opt/openflixr/version" ]]; then
                OF_VERSION_FULL=$(grep -o "^[0-9]\.[0-9]\.[0-9]" "/opt/openflixr/version" 2>> $LOG_FILE || echo "FAIL")
                if [[ ${OF_VERSION_FULL} == "FAIL" ]]; then
                    ERROR_MSG+=( "Could not get OpenFLIXR version from system file" )
                    echo -e "XXX\n100\Failure!\nXXX"
                    WAIT_STATUS_HOLD=666
                    break
                fi
            else
                OF_VERSION_FULL="FAIL"
                ERROR_MSG+=( "OpenFLIXR version file could not be found" )
                echo -e "XXX\n100\Failure!\nXXX"
                WAIT_STATUS_HOLD=666
                break
            fi
            OF_VERSION_MAJOR=$(cut -d'.' -f1 <<< $OF_VERSION_FULL)
            OF_VERSION_MINOR=$(cut -d'.' -f2 <<< $OF_VERSION_FULL)
            log "Getting OpenFLIXR web version"
            if [[ -f "/usr/share/nginx/html/setup/config.ini" ]]; then
                OF_VERSION_WEB=$(crudini --get /usr/share/nginx/html/setup/config.ini custom custom1 2>> $LOG_FILE || echo "FAIL")
                if [[ ${OF_VERSION_WEB} == "FAIL" ]]; then
                    ERROR_MSG+=( "Could not get OpenFLIXR version from nginx config.ini" )
                    echo -e "XXX\n100\Failure!\nXXX"
                    WAIT_STATUS_HOLD=666
                    break
                fi
            else
                OF_VERSION_WEB="FAIL"
                ERROR_MSG+=( "nginx config.ini could not be found" )
                echo -e "XXX\n100\Failure!\nXXX"
                WAIT_STATUS_HOLD=666
                break
            fi
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
                if [[ -n ${WAIT_STATUS_HOLD:-} ]]; then
                    WAIT_STATUS="${WAIT_STATUS_HOLD}"
                else
                    WAIT_STATUS=0
                fi
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
            666)
                error "Failed to find ready flags after ${duration}..."
                error "This means that you haven't updated or your update wasn't successful."
                info "Saving debug information to log..."
                if [[ ${#ERROR_MSG[@]} -gt 0 ]]; then
                    for ERROR in "${ERROR_MSG[@]}"; do
                        warning "${ERROR}"
                    done
                fi
                log "WAIT_STATUS: ${WAIT_STATUS}"
                log "OpenFLIXR version: ${OF_VERSION_FULL:-}"
                log "OpenFLIXR Web version: ${OF_VERSION_WEB:-}"
                log "OpenFLIXR updateof log file (last 5 lines)"
                tail -5 $UPDATEOF_LOGFILE >> $LOG_FILE
                log "OpenFLIXR onlineupdate log file (last 5 lines)"
                tail -5 $ONLINEUPDATE_LOGFILE >> $LOG_FILE
                log "OpenFLIXR update processes"
                echo ${OF_UPDATE_PS_FULL:-} >> $LOG_FILE
                error "Aborting OpenFLIXR Setup"
                exit 0
                ;;
            *)
                error "WAIT_STATUS not properly set..."
                info "Saving debug information to log..."
                if [[ ${#ERROR_MSG[@]} -gt 0 ]]; then
                    for ERROR in "${ERROR_MSG[@]}"; do
                        warning "${ERROR}"
                    done
                fi
                log "WAIT_STATUS: ${WAIT_STATUS}"
                log "OpenFLIXR version: ${OF_VERSION_FULL:-}"
                log "OpenFLIXR Web version: ${OF_VERSION_WEB:-}"
                log "OpenFLIXR updateof log file (last 5 lines)"
                tail -5 $UPDATEOF_LOGFILE >> $LOG_FILE
                log "OpenFLIXR onlineupdate log file (last 5 lines)"
                tail -5 $ONLINEUPDATE_LOGFILE >> $LOG_FILE
                log "OpenFLIXR update processes"
                echo ${OF_UPDATE_PS_FULL:-} >> $LOG_FILE
                error "Aborting OpenFLIXR Setup"
                exit 0
                ;;
        esac

        run_script 'set_config' "OPENFLIXR_READY" "YES"
    fi

    info "OpenFLIXR Ready"
}
