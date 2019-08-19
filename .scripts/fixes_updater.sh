#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

fixes_updater()
{
    info "Checking post update script..."
    if [[ $(grep -c "### Setup permissions fixes" "/opt/openflixr/userscript.sh") == 0 ]]; then
        info "- Adding setup permissions fixes to post update script"
        echo "" >> "/opt/openflixr/userscript.sh"
        echo "### Setup permissions fixes" >> "/opt/openflixr/userscript.sh"
        echo "sudo chmod +x /usr/local/bin/setupopenflixr" >> "/opt/openflixr/userscript.sh"
        echo "sudo chmod +x /usr/bin/setupopenflixr" >> "/opt/openflixr/userscript.sh"
        echo "### End Setup permissions fixes" >> "/opt/openflixr/userscript.sh"
        echo "" >> "/opt/openflixr/userscript.sh"
        info "- Done"
    else
        info "- Setup permissions fixes already included! =)"
    fi
}