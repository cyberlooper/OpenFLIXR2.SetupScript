#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

fixes_updater()
{
    info "Checking post update script..."

    info "Setup permissions fixes"
    if [[ ${config[FIRSTRUN_UPGRADE]:-} == "COMPLETED" || ${config[SETUP_COMPLETED]} == "Y" ]]; then
        if [[ $(grep -c "### setupopenflixr fixes" "/opt/openflixr/userscript.sh") == 0 ]]; then
            info "- Adding setupopenflixr fixes to post update script"
            echo "" >> "/opt/openflixr/userscript.sh"
            echo "### setupopenflixr fixes" >> "/opt/openflixr/userscript.sh"
            echo 'bash /opt/OpenFLIXR2.SetupScript/.scripts/userscript.sh # setupopenflixr fixes' >> "/opt/openflixr/userscript.sh"
            echo "" >> "/opt/openflixr/userscript.sh"
            info "- Done"
        fi
        if [[ $(grep -c "### Setup permissions fixes" "/opt/openflixr/userscript.sh") != 0 ]]; then
            info "- Removing setup permissions fixes from the post update script"
            sed -i 's/.*### Setup permissions fixes//g' "/opt/openflixr/userscript.sh"
            sed -i 's#.*sudo chmod +x /usr/local/bin/setupopenflixr##g' "/opt/openflixr/userscript.sh"
            sed -i 's#.*sudo chmod +x /usr/bin/setupopenflixr##g' "/opt/openflixr/userscript.sh"
            sed -i 's/.*### End Setup permissions fixes//g' "/opt/openflixr/userscript.sh"
            info "- Done"
        fi
    elif [[ $(grep -c "### Setup permissions fixes" "/opt/openflixr/userscript.sh") == 0 ]]; then
        info "- Adding setup permissions fixes to post update script"
        echo "" >> "/opt/openflixr/userscript.sh"
        echo "### Setup permissions fixes" >> "/opt/openflixr/userscript.sh"
        echo 'sudo chmod +x /usr/local/bin/setupopenflixr' >> "/opt/openflixr/userscript.sh"
        echo 'sudo chmod +x /usr/bin/setupopenflixr' >> "/opt/openflixr/userscript.sh"
        echo "### End Setup permissions fixes" >> "/opt/openflixr/userscript.sh"
        echo "" >> "/opt/openflixr/userscript.sh"
        info "- Done"
    else
        info "- Done"
    fi

    info "Custom user scripts"
    # Setup custom userscript structure
    if [[ ! -d "${DETECTED_HOMEDIR}/.openflixr/userscripts" ]]; then
        info "- Creating custom userscript structure"
        mkdir -p "${DETECTED_HOMEDIR}/.openflixr/userscripts"
    fi

    info "- Checking permissions"
    run_script 'fixes_permissions' >/dev/null

    # Custom userscript
    local USERSCRIPT="${DETECTED_HOMEDIR}/.openflixr/userscript.sh"
    if [[ ! -f "${USERSCRIPT}" ]]; then
        info "- Creating custom userscript file"
        echo "" > "${USERSCRIPT}"
        echo "# Run any custom scripts" > "${USERSCRIPT}"
        echo "run-parts --regex '^.*\.sh' \"${DETECTED_HOMEDIR}/.openflixr/userscripts\"" >> "${USERSCRIPT}"
    fi

    # Custom nginx blocks
    local USERSCRIPT_NGINX_ORDER=20
    local USERSCRIPT_NGINX="${DETECTED_HOMEDIR}/.openflixr/userscripts/${USERSCRIPT_NGINX_ORDER}_nginx.sh"
    if [[ ! -f "${USERSCRIPT_NGINX}" ]]; then
        info "- Creating custom nginx file"
        echo "" > "${USERSCRIPT_NGINX}"
        echo 'if [[ $(ls .openflixr/.nginx/*.block 2>/dev/null || true | wc -l) != 0 ]]; then' >> "${USERSCRIPT_NGINX}"
        echo "    cp .openflixr/.nginx/*.block /opt/openflixr/nginx/" >> "${USERSCRIPT_NGINX}"
        echo "    bash /opt/openflixr/createnginxconfig.sh" >> "${USERSCRIPT_NGINX}"
        echo "fi" >> "${USERSCRIPT_NGINX}"
    fi
    if [[ ! -d "${DETECTED_HOMEDIR}/.openflixr/.nginx" ]]; then
        info "- Creating custom nginx structure"
        mkdir -p "${DETECTED_HOMEDIR}/.openflixr/.nginx"
    fi

    # Add custom userscript to openflixr updater
    if [[ $(grep -c "bash ${USERSCRIPT}" "/opt/openflixr/userscript.sh") == 0 ]]; then
        info "- Adding custom userscript to post update script"
        echo "" >> "/opt/openflixr/userscript.sh"
        echo "### Custom userscript" >> "/opt/openflixr/userscript.sh"
        echo "bash ${USERSCRIPT} # Custom userscripts" >> "/opt/openflixr/userscript.sh"
        echo "### End Custom userscript" >> "/opt/openflixr/userscript.sh"
    fi

    info "- Done"
}