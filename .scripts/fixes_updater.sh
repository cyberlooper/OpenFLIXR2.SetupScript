#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

fixes_updater()
{
    info "Checking post update script..."

    if [[ ${config[FIRSTRUN_UPGRADE]:-} == "COMPLETED" || ${config[SETUP_COMPLETED]} == "Y" ]] && [[ $(grep -c "### setupopenflixr fixes" "/opt/openflixr/userscript.sh") == 0 ]]; then
        sed -i 's/.*#firstrun-startup//g' "${DETECTED_HOMEDIR}/.bashrc"
        if [[ $(grep -c "### Setup permissions fixes" "/opt/openflixr/userscript.sh") != 0 ]]; then
            info "- Removing setup permissions fixes from the post update script"
            sed -i 's/.*### Setup permissions fixes//g' "/opt/openflixr/userscript.sh"
            sed -i 's#.*sudo chmod +x /usr/local/bin/setupopenflixr##g' "/opt/openflixr/userscript.sh"
            sed -i 's#.*sudo chmod +x /usr/bin/setupopenflixr##g' "/opt/openflixr/userscript.sh"
            sed -i 's/.*### End Setup permissions fixes//g' "/opt/openflixr/userscript.sh"
            info "- Done"
        fi
        info "- Adding setupopenflixr fixes to post update script"
        echo "" >> "/opt/openflixr/userscript.sh"
        echo "### setupopenflixr fixes" >> "/opt/openflixr/userscript.sh"
        echo "bash /opt/OpenFLIXR2.SetupScript/.scripts/userscript.sh # setupopenflixr fixes" >> "/opt/openflixr/userscript.sh"
        echo "" >> "/opt/openflixr/userscript.sh"
        info "- Done"
    elif [[ $(grep -c "### Setup permissions fixes" "/opt/openflixr/userscript.sh") == 0 ]]; then
        info "- Adding setup permissions fixes to post update script"
        echo "" >> "/opt/openflixr/userscript.sh"
        echo "### Setup permissions fixes" >> "/opt/openflixr/userscript.sh"
        echo "sudo chmod +x /usr/local/bin/setupopenflixr" >> "/opt/openflixr/userscript.sh"
        echo "sudo chmod +x /usr/bin/setupopenflixr" >> "/opt/openflixr/userscript.sh"
        echo "### End Setup permissions fixes" >> "/opt/openflixr/userscript.sh"
        echo "" >> "/opt/openflixr/userscript.sh"
        info "- Done"
    else
        info "- Done"
    fi
}