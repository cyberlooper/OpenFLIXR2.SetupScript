#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

setup_configure_ombi_password()
{
    if [[ ${config[CHANGE_PASS]} == "Y" && ${OPENFLIXR_PASSWORD_NEW} != "" ]]; then
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
                log "  result=${result}"
                sleep 5s
                break
            fi
        done
    fi
}
