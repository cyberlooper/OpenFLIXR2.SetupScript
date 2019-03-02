#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

steps=(
    "Welcome"
    "Timezone"
    "Change Password"
    "Access"
    "Wait"
)

run_steps() {
    if [ "${config[STEPS_CURRENT]}" != "0" ]; then
        log "Configuration step set to ${config[STEPS_CURRENT]}"
        dialog \
            --backtitle "OpenFLIXR Setup" \
            --title "Resume?" \
            --clear \
            --yes-label "RESUME" \
            --no-label "START OVER" \
            --yesno "It has been detected that you last left off on Step ${config[STEPS_CURRENT]}. Do you want to [RESUME] from where you left off or [START OVER]?" \
            $HEIGHT $WIDTH

        if [ $? -eq 1 ]; then
            log "[START OVER] selected"
            set_config "STEPS_CURRENT" 0
            apps=()
        else
            log "[RESUME] selected"
            IFS=',' read -r -a apps <<< "${config[APPS]}"
        fi
        check_response $?
    fi

    for i in ${!steps[@]};
    do
        if [ "${config[STEPS_CURRENT]}" = "$i" ]; then
            step_number=$i
            step_name=${steps[$i]}
            step_file_name=$(echo "$step_name" | awk '{print tolower($0)}')
            step_file_name="step_${step_file_name// /_}"
            info "Running step ${step_number}: ${step_name}"
            run_script "${step_file_name}"
            run_script 'set_config' "STEPS_CURRENT" $((${config[STEPS_CURRENT]}+1))
        fi
    done
}