#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

fixes_ubooquity()
{
    info "Ubooquity fixes"
    info "- Checking version"
    VERSION_AVAILABLE=$(tac "/opt/ubooquity/logs/ubooquity.log" | grep -m1 "version" | cut -d '-' -f 3 | cut -d ' ' -f 5 || true)
    VERSION_CURRENT=$(tac "/opt/ubooquity/logs/ubooquity.log" | grep -m1 "version" | cut -d '-' -f 4 | cut -d ' ' -f 4 || true)
    debug "VERSION_AVAILABLE=${VERSION_AVAILABLE}"
    debug "VERSION_CURRENT=${VERSION_CURRENT}"
    if [[ ${VERSION_AVAILABLE} != ${VERSION_CURRENT} ]]; then
        info " - Updating"
        info "- Stopping Ubooquity"
        service ubooquity stop
        info "- Getting Ubooquity"
        wget -O /tmp/Ubooquity.zip http://vaemendis.net/ubooquity/service/download.php
        if [[ -f "/tmp/Ubooquity.jar" ]]; then
            rm "/tmp/Ubooquity.jar"
        fi
        debug "- Unzipping Ubooquity"
        unzip /tmp/Ubooquity.zip -d /tmp/
        info "- Updating Ubooquity"
        cp /tmp/Ubooquity.jar /opt/ubooquity/
        cp /opt/update/updates/configs/ubooquity.service /etc/systemd/system/ubooquity.service
        cp /opt/update/updates/configs/preferences.json /opt/ubooquity/
        if [[ -f "/opt/ubooquity/preferences.xml" ]]; then
            mv /opt/ubooquity/preferences.xml /opt/ubooquity/preferences.xml.bak
        fi
        systemctl daemon-reload
        systemctl enable ubooquity.service
        if [[ -d "/opt/ubooquity/themes/plextheme" ]]; then
            rm -r "/opt/ubooquity/themes/plextheme"
        fi
        git clone https://github.com/FinalAngel/plextheme /opt/ubooquity/themes/plextheme
        info "- Starting Ubooquity"
        service ubooquity start
    else
        info " - Up-to-date!"
    fi
    info "- Done"
}