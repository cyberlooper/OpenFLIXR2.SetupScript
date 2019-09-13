#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

fixes_updater()
{
    info "Checking post update script..."
    sed -i 's/.*#firstrun-startup//g' "${DETECTED_HOMEDIR}/.bashrc"
    if [[ $(grep -c "### Setup permissions fixes" "/opt/openflixr/userscript.sh") != 0 ]]; then
        info "- Removing setup permissions fixes from the post update script"
        sed -i 's/.*### Setup permissions fixes//g' "/opt/openflixr/userscript.sh"
        sed -i 's#.*sudo chmod +x /usr/local/bin/setupopenflixr##g' "/opt/openflixr/userscript.sh"
        sed -i 's#.*sudo chmod +x /usr/bin/setupopenflixr##g' "/opt/openflixr/userscript.sh"
        sed -i 's/.*### End Setup permissions fixes//g' "/opt/openflixr/userscript.sh"
        info "- Done"
    fi

    if [[ $(grep -c "### setupopenflixr fixes" "/opt/openflixr/userscript.sh") == 0 ]]; then
        info "- Adding setupopenflixr fixes to post update script"
        echo "" >> "/opt/openflixr/userscript.sh"
        echo "### setupopenflixr fixes" >> "/opt/openflixr/userscript.sh"
        echo "bash /opt/OpenFLIXR2.SetupScript/.scripts/userscript.sh # setupopenflixr fixes" >> "/opt/openflixr/userscript.sh"
    fi
}