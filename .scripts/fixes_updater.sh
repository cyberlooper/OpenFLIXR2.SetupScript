#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

fixes_updater()
{
    info "Checking post update script..."

    if [[ ${config[FIRSTRUN_UPGRADE]:-} == "COMPLETED" || ${config[SETUP_COMPLETED]} == "Y" ]] && [[ $(grep -c "### setupopenflixr fixes" "/opt/openflixr/userscript.sh") == 0 ]]; then
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
        echo 'bash /opt/OpenFLIXR2.SetupScript/.scripts/userscript.sh # setupopenflixr fixes' >> "/opt/openflixr/userscript.sh"
        echo "" >> "/opt/openflixr/userscript.sh"
        info "- Done"
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

    info "Updating Custom Userscripts"
    # Setup custom userscript structure
    if [[ ! -d "/home/openflixr/.openflixr/.nginx" ]]; then
        mkdir -p "/home/openflixr/.openflixr/.nginx"
    fi

    if [[ ! -d "/home/openflixr/.openflixr/userscripts" ]]; then
        mkdir -p "/home/openflixr/.openflixr/userscripts"
    fi

    # Custom nginx blocks
    echo "" > "/home/openflixr/.openflixr/userscripts/nginx.sh"
    echo 'if [[ $(ls .openflixr/.nginx/*.block 2>/dev/null || true | wc -l) != 0 ]]; then' >> "/home/openflixr/.openflixr/userscripts/nginx.sh"
    echo "    cp .openflixr/.nginx/*.block /opt/openflixr/nginx/" >> "/home/openflixr/.openflixr/userscripts/nginx.sh"
    echo "fi" >> "/home/openflixr/.openflixr/userscripts/nginx.sh"
    echo "bash /opt/openflixr/createnginxconfig.sh" >> "/home/openflixr/.openflixr/userscripts/nginx.sh"

    # Custom userscript
    echo "" > ".openflixr/userscript.sh"
    while IFS= read -r line; do
        echo "bash /home/openflixr/${line}" >> "/home/openflixr/.openflixr/userscript.sh"
    done < <(ls -la .openflixr/userscripts/*.sh | awk '{print $9}')

    if [[ $(grep -c "bash /home/openflixr/.openflixr/userscript.sh" "/opt/openflixr/userscript.sh") == 0 ]]; then
        echo "" >> "/opt/openflixr/userscript.sh"
        echo "### Custom userscript # custom userscripts" >> "/opt/openflixr/userscript.sh"
        echo "bash /home/openflixr/.openflixr/userscript.sh # custom userscripts" >> "/opt/openflixr/userscript.sh"
        echo "### End Custom userscript # custom userscripts" >> "/opt/openflixr/userscript.sh"
    fi

    info "- Done"
}