#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

step_timezone() {
    # Add domains that tzupdate uses for timezone lookup to pi-hole
    info "Adding some domains to pi-hole for timezone detection"
    pihole -w ip-api.com > /dev/null
    pihole -w freegeoip.app > /dev/null
    pihole -w geoip.nekudo.com > /dev/null
    pihole -w timezoneapi.io > /dev/null

    # Run timezone selector
    run_script 'tzSelectionMenu' ${BACKTITLE}

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
    pihole -w -d ip-api.com > /dev/null
    pihole -w -d freegeoip.app > /dev/null
    pihole -w -d geoip.nekudo.com > /dev/null
    pihole -w -d timezoneapi.io > /dev/null
}
