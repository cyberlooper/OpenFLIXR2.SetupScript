#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

steps=(
    "Welcome"
    "Change Password"
    "Network Configuration"
    "Access"
    "Folder Creation"
    "Folder Mounting"
    "Wait"
    "Timezone"
)

run_steps() {
    if [ "${config[STEPS_CURRENT]}" != "0" ]; then
        if run_script 'question_prompt' Y "It has been detected that you last left off on Step ${config[STEPS_CURRENT]}. Do you want to resume from where you left off?" "Resume?" "OpenFLIXR Setup"; then
            info "Chose to resume"
        else
            info "Chose to start over"
            set_config "STEPS_CURRENT" 0
        fi
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