#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

submit_logs() {
    if [[ "${config[SUBMITTED_LOGS_VERSION]}" != "${LOCAL_COMMIT}" ]]; then
        debug "ALWAYS_SUBMIT_LOGS=${config[ALWAYS_SUBMIT_LOGS]}"
        if [[ ${config[ALWAYS_SUBMIT_LOGS]} != "Y" ]]; then
            if run_script 'question_prompt' Y $"${SUBMIT_MESSAGE}" "Submit Logs?" ${OF_BACKTITLE}; then
                if [[ ${config[ALWAYS_SUBMIT_LOGS]} == "" ]]; then
                    if run_script 'question_prompt' Y "Do you want to always submit the logs on error?" "Submit Logs?" ${OF_BACKTITLE}; then
                        run_script 'set_config' "ALWAYS_SUBMIT_LOGS" "Y"
                    else
                        run_script 'set_config' "ALWAYS_SUBMIT_LOGS" "N"
                    fi
                fi
                SUBMIT_LOGS="Y"
            else
                SUBMIT_LOGS="N"
            fi
        elif [[ ${config[ALWAYS_SUBMIT_LOGS]} == "Y" ]]; then
            SUBMIT_LOGS="Y"
        fi

        if [[ ${SUBMIT_LOGS} == "Y" ]]; then
            DISCORD_USERNAME=$(whiptail \
                    --backtitle ${OF_BACKTITLE} \
                    --title "Discord Username" \
                    --inputbox $"Please provide your Discord username for submission.\nIf you don't have one, join the Discord then enter it here.\nBe sure to join the OpenFLIXR Discord server so that I may contact, if needed\nOtherwise, leave this blank to submit anonymously." 0 0 "${config[DISCORD_USERNAME]:-}" 3>&1 1>&2 2>&3)
                run_script 'check_response' $?;
            DISCORD_USERNAME=${DISCORD_USERNAME%%#*}

            if [[ ${DISCORD_USERNAME} != "" ]]; then
                run_script 'set_config' "DISCORD_USERNAME" "${DISCORD_USERNAME}"
            fi

            local FILE="${config[DISCORD_USERNAME]:-Anonymous}_setup_logs.tar"
            local FILE_PATH="/tmp/${FILE}"
            local SUBMISSION_ID=$(uuidgen | tr -d - | tr -d '' | tr '[:upper:]' '[:lower:]')
            readonly WEBHOOK_URL="https://api.tarpix.net/ofv1/of-log-submit"

            info "Collecting logs..."
            tar -cf "${FILE_PATH}" /var/log/openflixr_setup.* > /dev/null 2>&1
            info "Submitting logs..."
            bash ${SCRIPTPATH}/.scripts/discord.sh \
                --webhook-url="${WEBHOOK_URL}" \
                --file "${FILE_PATH}" \
                --text "Setup logs reported from ${config[DISCORD_USERNAME]:-Anonymous}\nSubmission ID: ${SUBMISSION_ID}"

            if [[ $? == 0 ]]; then
                info "Logs submitted successfully!"
                info "Your submission ID is: ${SUBMISSION_ID}"
                info "Keep an eye out for a message on the OpenFLIXR Discord for updates."
                SUBMITTED_LOGS="Y"
                run_script 'set_config' "SUBMITTED_LOGS" "Y"
                run_script 'set_config' "SUBMITTED_LOGS_VERSION" "$LOCAL_COMMIT"
            else
                warning "Well this is embarassing... Automatic submission failed =("
                warning "You will need to manually submit your logs."
                warning "For more information, visit the troubleshooting section of the OpenFLIXR Setup Script:"
                warning "https://github.com/openflixr/OpenFLIXR2.SetupScript#troubleshooting"
                run_script 'set_config' "SUBMITTED_LOGS" "N"
            fi
        else
            warning "Not submitting the logs automatically."
            warning "You will need to do this yourself, run the setup again or run 'sudo setupopenflixr -l' to return to this prompt."
            warning "For more information, visit the troubleshooting section of the OpenFLIXR Setup Script:"
            warning "https://github.com/openflixr/OpenFLIXR2.SetupScript#troubleshooting"
        fi
    else
        warning "You have already submitted logs for this version of the setup script."
        warning "Please wait for an update before trying again. Thanks!"
    fi
}
