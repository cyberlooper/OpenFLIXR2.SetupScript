#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

setup_configure_ombi_password()
{
    if [[ ${config[CHANGE_PASS]} == "Y" && ${OPENFLIXR_PASSWORD_NEW} != "" ]]; then
        info "- Checking to make sure Ombi is ready..."
        if [[ $(run_script 'check_application_ready' "http://localhost:3579/request") == "200" ]]; then
            info "- Updating Password"
            local result
            local password_old=${OPENFLIXR_PASSWORD_OLD}
            local openflixr_ombi_id=$(sqlite3 /opt/Ombi/Ombi.db "SELECT Id FROM AspNetUsers WHERE NormalizedUserName='OPENFLIXR';")
            while true; do
                debug "  password_old=${password_old}"
                result=$(curl -s -X PUT "http://localhost:3579/api/v1/Identity/local" \
                            -H "accept: application/json" \
                            -H "ApiKey: ${API_KEYS[ombi]}" \
                            -H "Content-Type: application/json-patch+json" \
                            -d "{
                                    \"id\":\"${openflixr_ombi_id}\",
                                    \"username\":\"openflixr\",
                                    \"confirmNewPassword\":\"${OPENFLIXR_PASSWORD_NEW}\",
                                    \"currentPassword\":\"${password_old}\",
                                    \"password\":\"${OPENFLIXR_PASSWORD_NEW}\"
                                }" || echo 'error')
                log "  result=${result}"
                local result_successful
                if [[ ${result} == "Invalid API Key" ]]; then
                    error "  Something went wrong and the Ombi API Key is not correct..."
                    warning "  You will need to update the password manually after the setup completes."
                fi
                result_successful=$(jq '.successful?' <<< $result)
                log "  result_successful=${result_successful}"
                if [[ "${result_successful}" == "true" ]]; then
                    info "  Password updated successfully!"
                    break
                elif [[ ${password_old} != "openflixr" ]]; then
                    password_old="openflixr"
                else
                    error "  Password did not update successfully =("
                    warning "  You will need to update it manually after the setup completes."
                    sleep 5s
                    break
                fi
            done
        else
            error "  Ombi was not ready to receive requests after 30s..."
            warning "  You will need to manually configure the Ombi password after setup completes."
            sleep 5s
        fi
    fi
}
