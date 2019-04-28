#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

setup_configure_ombi_password()
{
    if [[ ${config[CHANGE_PASS]} == "Y" && ${OPENFLIXR_PASSWORD_NEW} != "" ]]; then
        info "- Updating Password"
    fi
        OPENFLIXR_PASSWORD_OLD="notMyPassword"
        local result
        local password_old=${OPENFLIXR_PASSWORD_OLD}
        while true; do
            debug "  password_old=${password_old}"
            result=$(curl -s -X PUT "http://localhost:3579/api/v1/Identity/local" \
                        -H "accept: application/json" \
                        -H "ApiKey: ${API_KEYS[ombi]}" \
                        -H "Content-Type: application/json-patch+json" \
                        -d "{
                                \"id\":\"3fcf1b4e-743a-4a00-a75c-a9675f7cea6a\",
                                \"username\":\"openflixr\",
                                \"confirmNewPassword\":\"${OPENFLIXR_PASSWORD_NEW}\",
                                \"currentPassword\":\"${password_old}\",
                                \"password\":\"${OPENFLIXR_PASSWORD_NEW}\"}" \
                    | jq '.successful' || echo 'error')

            if [[ "${result}" == "true" ]]; then
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
}
