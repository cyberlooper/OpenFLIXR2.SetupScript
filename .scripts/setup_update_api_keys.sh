#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

setup_update_api_keys()
{
    info "Updating API Keys"
    ## htpcmanager
    info "-- HTPC"
    for service in "${!API_KEYS[@]}"; do
        if [[ "${service}" != "monit"
            && "${service}" != "htpcmanager"
            && "${service}" != "lidarr"
            && "${service}" != "lazylibrarian"
            && "${service}" != "mopidy"
            && "${service}" != "nzbhydra2"
        ]]; then
            info "   Updating HTPC for ${service}"
            if [[ "${service}" == "jackett" ]]; then
                sqlite3 /opt/HTPCManager/userdata/database.db "UPDATE setting SET val='${API_KEYS[$service]}' where key='torrents_${service}_apikey';"
            else
                sqlite3 /opt/HTPCManager/userdata/database.db "UPDATE setting SET val='${API_KEYS[$service]}' where key='${service}_apikey';"
            fi
        fi
    done
    ## couchpotato
    info "-- Couchpotato"
    crudini --set /opt/CouchPotato/settings.conf core api_key ${API_KEYS[couchpotato]}
    crudini --set /opt/CouchPotato/settings.conf sabnzbd api_key ${API_KEYS[sabnzbd]}
    ## sickrage
    info "-- Sickrage"
    crudini --set /opt/sickrage/config.ini SABnzbd sab_apikey ${API_KEYS[sabnzbd]}
    crudini --set /opt/sickrage/config.ini General api_key ${API_KEYS[sickrage]}
    ## headphones
    info "-- Headphones"
    crudini --set /opt/headphones/config.ini General api_key ${API_KEYS[headphones]}
    crudini --set /opt/headphones/config.ini SABnzbd sab_apikey ${API_KEYS[sabnzbd]}
    ## mylar
    info "-- Mylar"
    crudini --set /opt/Mylar/config.ini General api_key ${API_KEYS[mylar]}
    crudini --set /opt/Mylar/config.ini SABnzbd sab_apikey ${API_KEYS[sabnzbd]}
    ## jackett
    info "-- Jackett"
    sed -i 's/"APIKey":.*,/"APIKey": "'${API_KEYS[jackett]}'", /g' /root/.config/Jackett/ServerConfig.json
    ## sonarr
    info "-- Sonarr"
    sed -i 's/^  <ApiKey>.*/  <ApiKey>'${API_KEYS[sonarr]}'<\/ApiKey>/' /root/.config/NzbDrone/config.xml
    #Sabnzbd en NZBget API keys invullen, voor alle applicaties / Enter Sabnzbd and NZBget API keys for all applications
    ## radarr
    info "-- Radarr"
    sed -i 's/^  <ApiKey>.*/  <ApiKey>'${API_KEYS[radarr]}'<\/ApiKey>/' /root/.config/Radarr/config.xml
    ## lidarr
    info "-- Lidarr"
    sed -i 's/^  <ApiKey>.*/  <ApiKey>'${API_KEYS[lidarr]}'<\/ApiKey>/' /home/openflixr/.config/Lidarr/config.xml
    ## lazylibrarian
    info "-- Lazylibrarian"
    crudini --set /opt/LazyLibrarian/lazylibrarian.ini SABnzbd sab_apikey ${API_KEYS[sabnzbd]}

    ## nzbhydra (is dat de enige apiKey? / is that the only apiKey?)
    #/opt/nzbhydra2/data/nzbhydra.yml apiKey: "aqpep52c61fkbc8br0tiu53508"

    ## plexpy
    info "-- Tautulli (PlexPy)"
    sed -i "s/api_key =.*/api_key = \"${API_KEYS[plexpy]}\"/g" "/opt/plexpy/config.ini"

    ## Ombi (plexrequests)
    info "-- Ombi (plexrequests)"
    OMBI_TOKEN=$(curl -s -X POST "http://localhost:3579/api/v1/Token" -H "accept: application/json" -H "Content-Type: application/json" -d "{ \"username\": \"openflixr\", \"password\": \"$oldpassword\"}" | jq -r '.access_token' | tr -d '[:space:]')
    API_KEYS[ombi]=$(curl -s -X GET --header 'Accept: application/json' --header 'Content-Type: application/json' --header 'Authorization: Bearer '$OMBI_TOKEN'' 'http://localhost:3579/request/api/v1/Settings/Ombi/' | jq -r '.apiKey' | tr -d '[:space:]')

    local ENABLED_HTPC
    local ENABLED_OMBI

    info "   Movies Manager"
    if [ "${config[MOVIE_MANAGER]}" == 'couchpotato' ]; then
        info "   - Enabling Couchpotato in OMBI and HTPC"
        ENABLED_HTPC="on"
        ENABLED_OMBI="true"
    else
        info "   - Disabling Couchpotato in OMBI and HTPC"
        ENABLED_HTPC="0"
        ENABLED_OMBI="false"
    fi

    curl -s -X POST --header 'Content-Type: application/json' --header 'Accept: application/json' -d '{
    "ApiKey": "'${API_KEYS[couchpotato]}'",
    "Enabled": '$ENABLED_OMBI',
    "Ip": "localhost",
    "Port": 5050,
    "SubDir": "couchpotato"
    }' 'http://localhost:3579/request/api/v1/settings/couchpotato?apikey='${API_KEYS[ombi]}'' >> $LOG_FILE

    #sqlite3 /opt/HTPCManager/userdata/database.db "UPDATE setting SET val='${ENABLED_HTPC}' where key='couchpotato_enable';"

    if [ "${config[MOVIE_MANAGER]}" == 'radarr' ]; then
        info "   - Enabling Radarr in OMBI and HTPC"
        ENABLED_HTPC="on"
        ENABLED_OMBI="true"
    else
        info "   - Disabling Radarr in OMBI and HTPC"
        ENABLED_HTPC="0"
        ENABLED_OMBI="false"
    fi

    curl -s -X POST --header 'Content-Type: application/json' --header 'Accept: application/json' -d '{
    "ApiKey": "'${API_KEYS[radarr]}'",
    "Enabled": '$ENABLED_OMBI',
    "Ip": "localhost",
    "Port": 5050,
    "SubDir": "radarr"
    }' 'http://localhost:3579/request/api/v1/settings/radarr?apikey='${API_KEYS[ombi]}'' >> $LOG_FILE

    #sqlite3 /opt/HTPCManager/userdata/database.db "UPDATE setting SET val='${ENABLED_HTPC}' where key='couchpotato_enable';"

    info "   TV Show Manager"
    if [ "${config[SERIES_MANAGER]}" == 'sickrage' ]; then
        info "   - Enabling Sickrage in OMBI and HTPC"
        ENABLED_HTPC="on"
        ENABLED_OMBI="true"
    else
        info "   - Disabling Sickrage in OMBI and HTPC"
        ENABLED_HTPC="0"
        ENABLED_OMBI="false"
    fi
    curl -s -X POST --header 'Content-Type: application/json' --header 'Accept: application/json' -d '{
    "ApiKey": "'${API_KEYS[sickrage]}'",
    "qualityProfile": "default",
    "Enabled": '$ENABLED_OMBI',
    "Ip": "localhost",
    "Port": 8081,
    "SubDir": "sickrage"
    }' 'http://localhost:3579/request/api/v1/settings/sickrage?apikey='${API_KEYS[ombi]}'' >> $LOG_FILE

    sqlite3 /opt/HTPCManager/userdata/database.db "UPDATE setting SET val='${ENABLED_HTPC}' where key='sickrage_enable';"

    if [ "${config[SERIES_MANAGER]}" == 'sonarr' ]; then
        info "   - Enabling Sonarr in OMBI and HTPC"
        ENABLED_HTPC="on"
        ENABLED_OMBI="true"
    else
        info "   - Disabling Sickrage in OMBI and HTPC"
        ENABLED_HTPC="0"
        ENABLED_OMBI="false"
    fi
    curl -s -X POST --header 'Content-Type: application/json' --header 'Accept: application/json' -d '{
    "ApiKey": "'${API_KEYS[sickrage]}'",
    "qualityProfile": "default",
    "Enabled": '$ENABLED_OMBI',
    "Ip": "localhost",
    "Port": 8081,
    "SubDir": "sonarr"
    }' 'http://localhost:3579/request/api/v1/settings/sonarr?apikey='${API_KEYS[ombi]}'' >> $LOG_FILE

    sqlite3 /opt/HTPCManager/userdata/database.db "UPDATE setting SET val='${ENABLED_HTPC}' where key='sonarr_enable';"

# Ombi dropped support for Headphones
#    info "   Updating API Key for Headphones"
#    curl -s -X POST --header 'Content-Type: application/json' --header 'Accept: application/json' -d '{
#    "ApiKey": "'${API_KEYS[headphones]}'",
#    "Enabled": true,
#    "Ip": "localhost",
#    "Port": 8181,
#    "SubDir": "headphones"
#    }' 'http://localhost:3579/request/api/v1/settings/headphones?apikey='${API_KEYS[ombi]}'' >> $LOG_FILE

    if [[ ! $password = "" ]]; then
        info "   Updating Password"
        curl -s -X PUT --header 'Content-Type: application/json' --header 'Accept: application/json' -d '{
        "CurrentPassword": "'$oldpassword'",
        "NewPassword": "'$password'"
        }' 'http://localhost:3579/request/api/credentials/openflixr?apikey='${API_KEYS[ombi]}'' >> $LOG_FILE
    fi

    ## usenet
    info "-- Usenet"
    if [ "$usenetpassword" != '' ]; then
        service sabnzbdplus stop
        sleep 5
        sed -i 's/^api_key.*/api_key = '1234567890'/' /home/openflixr/.sabnzbd/sabnzbd.ini
        service sabnzbdplus start
        sleep 5
        curl -s 'http://localhost:8080/api?mode=set_config&section=servers&keyword=OpenFLIXR_Usenet_Server&output=xml&enable=1&apikey=1234567890'
        curl -s 'http://localhost:8080/api?mode=set_config&section=servers&keyword=OpenFLIXR_Usenet_Server&output=xml&ssl=$usenetssl&apikey=1234567890'
        curl -s 'http://localhost:8080/api?mode=set_config&section=servers&keyword=OpenFLIXR_Usenet_Server&output=xml&displayname=$usenetdescription&apikey=1234567890'
        curl -s 'http://localhost:8080/api?mode=set_config&section=servers&keyword=OpenFLIXR_Usenet_Server&output=xml&username=$usenetusername&apikey=1234567890'
        curl -s 'http://localhost:8080/api?mode=set_config&section=servers&keyword=OpenFLIXR_Usenet_Server&output=xml&password=$usenetpassword&apikey=1234567890'
        curl -s 'http://localhost:8080/api?mode=set_config&section=servers&keyword=OpenFLIXR_Usenet_Server&output=xml&host=$usenetservername&apikey=1234567890'
        curl -s 'http://localhost:8080/api?mode=set_config&section=servers&keyword=OpenFLIXR_Usenet_Server&output=xml&port=$usenetport&apikey=1234567890'
        curl -s 'http://localhost:8080/api?mode=set_config&section=servers&keyword=OpenFLIXR_Usenet_Server&output=xml&connections=$usenetthreads&apikey=1234567890'
        service sabnzbdplus stop
        sed -i 's/^api_key.*/api_key = '${API_KEYS[sabnzbd]}'/' /home/openflixr/.sabnzbd/sabnzbd.ini
    else
        service sabnzbdplus stop
        sleep 5
        sed -i 's/^api_key.*/api_key = '1234567890'/' /home/openflixr/.sabnzbd/sabnzbd.ini
        service sabnzbdplus start
        sleep 5
        curl -s 'http://localhost:8080/api?mode=set_config&section=servers&keyword=OpenFLIXR_Usenet_Server&output=xml&enable=0&apikey=1234567890'
        service sabnzbdplus stop
        sed -i 's/^api_key.*/api_key = '${API_KEYS[sabnzbd]}'/' /home/openflixr/.sabnzbd/sabnzbd.ini
    fi
    ## newznab
    # info "-- Tautulli (PlexPy)"
    #    if [ "$newznabapi" != '' ]
    #        then
    #         newznab config
    #        else
    #         reverse
    #    fi
    ## tv shows downloader
}