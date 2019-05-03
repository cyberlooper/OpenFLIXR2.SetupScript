#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

step_timezone() {
    if [[ "${config[OPENFLIXR_TIMEZONE_SHORT]}" == "" ]]; then
        log "Timezone not set."
        CHANGE_TZ="Y"
    elif run_script 'question_prompt' N "Your current timezone is set to ${config[OPENFLIXR_TIMEZONE_SHORT]}.\nDo you want to change it?" "Step ${step_number}: ${step_name}"; then
        log "Timezone set: ${config[OPENFLIXR_TIMEZONE_SHORT]}. User chose to change the timezone."
        CHANGE_TZ="Y"
    else
        log "Timezone set: ${config[OPENFLIXR_TIMEZONE_SHORT]}. User chose to keep the timezone."
        CHANGE_TZ="N"
    fi

    if [[ "$CHANGE_TZ" == "Y" ]]; then
        # Add domains that tzupdate uses for timezone lookup to pi-hole
        info "Adding some domains to pi-hole for timezone detection"
        pihole -w ip-api.com 2>&1 >> $LOG_FILE
        pihole -w freegeoip.app 2>&1 >> $LOG_FILE
        pihole -w geoip.nekudo.com 2>&1 >> $LOG_FILE
        pihole -w timezoneapi.io 2>&1 >> $LOG_FILE

        # Run timezone selector
        run_script 'tzSelectionMenu' ${OF_BACKTITLE}

        if [ "$TZ_CORRECT" = "Y" ]; then
            set_config "OPENFLIXR_TIMEZONE" $detected
            set_config "OPENFLIXR_TIMEZONE_SHORT" $detected_short
            info "Timezone detected: $detected_short"
        else
            set_config "OPENFLIXR_TIMEZONE" $selected
            set_config "OPENFLIXR_TIMEZONE_SHORT" $selected_short
            info "Timezone selected: $selected_short"
        fi

        # Remove domains that tzupdate uses for timezone lookup to pihole
        info "Removing some domains to pi-hole for timezone detection"
        pihole -w -d ip-api.com 2>&1 >> $LOG_FILE
        pihole -w -d freegeoip.app 2>&1 >> $LOG_FILE
        pihole -w -d geoip.nekudo.com 2>&1 >> $LOG_FILE
        pihole -w -d timezoneapi.io 2>&1 >> $LOG_FILE
    else
        log "Keeping current timezone setting."
    fi
}
