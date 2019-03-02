#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

step_timezone() {
    # Run timezone selector
    run_script 'tzSelectionMenu' "OpenFLIXR Setup"

    if [ $selected = 0 ]; then
        set_config "OPENFLIXR_TIMEZONE" $detected
        set_config "OPENFLIXR_TIMEZONE_SHORT" $detected_short
    else
        set_config "OPENFLIXR_TIMEZONE" $selected
        set_config "OPENFLIXR_TIMEZONE_SHORT" $selected_short
    fi
}
