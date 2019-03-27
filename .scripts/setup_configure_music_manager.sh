#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

setup_configure_music_manager()
{
    info "Configuring Music Manager"
    info "- Headphones"
    info "  Updaing API Key"
    crudini --set /opt/headphones/config.ini General api_key ${API_KEYS[headphones]}
    crudini --set /opt/headphones/config.ini SABnzbd sab_apikey ${API_KEYS[sabnzbd]}

    if [ "$headphonespass" != '' ]
        info "  Enabling Headphones VIP"
        then
        crudini --set /opt/headphones/config.ini General hpuser $headphonesuser
        crudini --set /opt/headphones/config.ini General hppass $headphonespass
        crudini --set /opt/headphones/config.ini General headphones_indexer 1
        crudini --set /opt/headphones/config.ini General mirror headphones
    else
        crudini --set /opt/headphones/config.ini General hpuser
        crudini --set /opt/headphones/config.ini General hppass
        crudini --set /opt/headphones/config.ini General headphones_indexer 0
        crudini --set /opt/headphones/config.ini General mirror musicbrainz.org
    fi

    info "- Lidarr"
    info "  Updaing API Key"
    sed -i 's/^  <ApiKey>.*/  <ApiKey>'${API_KEYS[lidarr]}'<\/ApiKey>/' /home/openflixr/.config/Lidarr/config.xml
}
