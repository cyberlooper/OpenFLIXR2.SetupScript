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

    debug "OPENFLIXR_READY='${config[OPENFLIXR_READY]}'"
    if [[ "${config[OPENFLIXR_READY]}" != "YES" ]]; then
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
                OF_VERSION_FULL=$(grep -o "^[0-9]\.[0-9]\.[0-9]" /opt/openflixr/version)
                OF_VERSION_MAJOR=$(cut -d'.' -f1 <<< $OF_VERSION_FULL)
                OF_VERSION_MINOR=$(cut -d'.' -f2 <<< $OF_VERSION_FULL)
                OF_VERSION_WEB=$(crudini --get /usr/share/nginx/html/setup/config.ini custom custom1)
                OF_VERSION_WEB_MAJOR=$(cut -d'.' -f1 <<< $OF_VERSION_FULL)
                OF_VERSION_WEB_MINOR=$(cut -d'.' -f2 <<< $OF_VERSION_FULL)
                #TODO: Why does this cause an error? - OF_UPDATE_PS=$(ps -ef | grep -i update | grep -v grep | grep -v shellinabox | grep -v tail | cut -c1-5)
                if [[ -f "/opt/OpenFLIXR2.SetupScript/stop_wait" ]]; then
                    echo -e "XXX\n100\Skipping wait!\nXXX"
                    break
                elif [[ "$UPDATEOF_LOG_LINE" = "updateof finished"
                        || "$ONLINEUPDATE_LOG_LINE" = "onlineupdate finished" ]]; then
                    echo -e "XXX\n100\nDone!\nXXX"
                    break
                elif [[ "${OF_VERSION_FULL}" == "${OF_VERSION_WEB}"
                        && $(echo "${OF_VERSION_MAJOR}.${OF_VERSION_MINOR} >= 2.9" | bc -l) = 1
                        && $(echo "${OF_VERSION_WEB_MAJOR}.${OF_VERSION_WEB_MINOR} >= 2.9" | bc -l) = 1 ]]; then
                        #&& "${OF_UPDATE_PS}" == "" ]]; then
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
        OF_VERSION_FULL=$(grep -o "^[0-9]\.[0-9]\.[0-9]" /opt/openflixr/version)
        OF_VERSION_MAJOR=$(cut -d'.' -f1 <<< $OF_VERSION_FULL)
        OF_VERSION_MINOR=$(cut -d'.' -f2 <<< $OF_VERSION_FULL)
        OF_VERSION_WEB=$(crudini --get /usr/share/nginx/html/setup/config.ini custom custom1)
        OF_VERSION_WEB_MAJOR=$(cut -d'.' -f1 <<< $OF_VERSION_FULL)
        OF_VERSION_WEB_MINOR=$(cut -d'.' -f2 <<< $OF_VERSION_FULL)
        #TODO: See above - OF_UPDATE_PS=$(ps -ef | grep -i update | grep -v grep | grep -v shellinabox | grep -v tail | cut -c1-5)
        if [[ -f "/opt/OpenFLIXR2.SetupScript/stop_wait" ]]; then
            warning "Found stop_wait file. Skipping the wait step."
            info "Removing stop_wait file"
            rm "/opt/OpenFLIXR2.SetupScript/stop_wait" || warning "Could not remove stop_wait file. Please remove manually: /opt/OpenFLIXR2.SetupScript/stop_wait"
        elif [[ "$UPDATEOF_LOG_LINE" = "updateof finished" ]]; then
            info "Found 'updateof finished' in $UPDATEOF_LOGFILE"
        elif [[ "$ONLINEUPDATE_LOG_LINE" = "onlineupdate finished" ]]; then
            info "Found 'onlineupdate finished' in $ONLINEUPDATE_LOGFILE"
        elif [[ "${OF_VERSION_FULL}" == "${OF_VERSION_WEB}"
                && $(echo "${OF_VERSION_MAJOR}.${OF_VERSION_MINOR} >= 2.9" | bc -l) = 1
                && $(echo "${OF_VERSION_WEB_MAJOR}.${OF_VERSION_WEB_MINOR} >= 2.9" | bc -l) = 1 ]]; then
                #&& "${OF_UPDATE_PS}" == "" ]]; then
            info "OpenFLIXR versions match!"
        else
            warning "Failed to find ready flags after ${duration}."
            info "Logging OpenFLIXR updateof log file (last 5 lines)"
            tail -5 $UPDATEOF_LOGFILE
            tail -5 $UPDATEOF_LOGFILE >> $LOG_FILE
            info "Logging OpenFLIXR onlineupdate log file (last 5 lines)"
            tail -5 $ONLINEUPDATE_LOGFILE
            tail -5 $ONLINEUPDATE_LOGFILE >> $LOG_FILE
            info "OpenFLIXR version: ${OF_VERSION_FULL}"
            info "OpenFLIXR Web version: ${OF_VERSION_WEB}"
            info "Logging OpenFLIXR update processes"
            $(ps -ef | grep -i update | grep -v grep | grep -v shellinabox | grep -v tail) >> $LOG_FILE
            fatal "Exiting OpenFLIXR Setup"
            exit 1
        fi

        run_script 'set_config' "OPENFLIXR_READY" "YES"
    fi

    info "OpenFLIXR Ready"
}
