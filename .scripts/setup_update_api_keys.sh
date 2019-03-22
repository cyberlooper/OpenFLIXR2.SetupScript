#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

setup_update_api_keys()
{
    info "Updating API Keys"
    ## htpcmanager
    echo "- HTPC"
    for service in "${SERVICES[@]}"; do
        if [[ "${service}" != "monit" ]] && [[ "${service}" != "htpcmanager" ]]
            && [[ "${service}" != "lidarr" ]] && [[ "${service}" != "lazylibrarian" ]]
            && [[ "${service}" != "mopidy" ]] && [[ "${service}" != "nzbhydra2" ]]; then
            if [[ "${service}" == "jackett" ]]; then
                sqlite3 /opt/HTPCManager/userdata/database.db "UPDATE setting SET val='${API_KEYS[$service]}' where key='torrents_${service}_apikey';"
            else
                sqlite3 /opt/HTPCManager/userdata/database.db "UPDATE setting SET val='${API_KEYS[$service]}' where key='${service}_apikey';"
            fi
        fi
    done
    ## couchpotato
    echo "- Couchpotato"
    crudini --set /opt/CouchPotato/settings.conf core api_key ${API_KEYS[couchpotato]}
    crudini --set /opt/CouchPotato/settings.conf sabnzbd api_key ${API_KEYS[sabnzbd]}
    ## sickrage
    echo "- Sickrage"
    crudini --set /opt/sickrage/config.ini SABnzbd sab_apikey ${API_KEYS[sabnzbd]}
    crudini --set /opt/sickrage/config.ini General api_key ${API_KEYS[sickrage]}
    ## headphones
    echo "- Headphones"
    crudini --set /opt/headphones/config.ini General api_key ${API_KEYS[headphones]}
    crudini --set /opt/headphones/config.ini SABnzbd sab_apikey ${API_KEYS[sabnzbd]}
    ## mylar
    echo "- Mylar"
    crudini --set /opt/Mylar/config.ini General api_key ${API_KEYS[mylar]}
    crudini --set /opt/Mylar/config.ini SABnzbd sab_apikey ${API_KEYS[sabnzbd]}
    ## jackett
    echo "- Jackett"
    sed -i 's/"APIKey": "03fl3cs2txrxmrvpwmb2sp8b73ko4frl".*,/"APIKey": "'${API_KEYS[jackett]}'", /g' /root/.config/Jackett/ServerConfig.json
    ## sonarr
    echo "- Sonarr"
    sed -i 's/^  <ApiKey>.*/  <ApiKey>'${API_KEYS[sonarr]}'<\/ApiKey>/' /root/.config/NzbDrone/config.xml
    #Sabnzbd en NZBget API keys invullen, voor alle applicaties
    ## radarr
    echo "- Radarr"
    sed -i 's/^  <ApiKey>.*/  <ApiKey>'${API_KEYS[radarr]}'<\/ApiKey>/' /root/.config/Radarr/config.xml
    ## lidarr
    echo "- Lidarr"
    sed -i 's/^  <ApiKey>.*/  <ApiKey>'${API_KEYS[lidarr]}'<\/ApiKey>/' /home/openflixr/.config/Lidarr/config.xml
    ## lazylibrarian
    echo "- Lazylibrarian"
    crudini --set /opt/LazyLibrarian/lazylibrarian.ini SABnzbd sab_apikey ${API_KEYS[sabnzbd]}

    #[USENET]
    nzb_downloader_sabnzbd=1
    nzb_downloader_nzbget=0

    ## nzbhydra (is dat de enige apiKey?)
    #/opt/nzbhydra2/data/nzbhydra.yml apiKey: "aqpep52c61fkbc8br0tiu53508"

    ## plexpy
    echo "- Tautulli (PlexPy)"
    sed -i "s/api_key =.*/api_key = \"${API_KEYS[plexpy]}\"/g" "/opt/plexpy/config.ini"

    ## plexrequests
    echo "- PlexRequests"
    OMBI_TOKEN=$(curl -s -X POST "http://localhost:3579/api/v1/Token" -H "accept: application/json" -H "Content-Type: application/json" -d "{ \"username\": \"openflixr\", \"password\": \"$oldpassword\"}" | jq -r '.access_token' | tr -d '[:space:]')
    API_KEYS[ombi]=$(curl -s -X GET --header 'Accept: application/json' --header 'Content-Type: application/json' --header 'Authorization: Bearer '$OMBI_TOKEN'' 'http://localhost:3579/request/api/v1/Settings/Ombi/' | jq -r '.apiKey' | tr -d '[:space:]')
    echo ""
    echo "-- Updating API Key for Couchpotato"
    curl -s -X POST --header 'Content-Type: application/json' --header 'Accept: application/json' -d '{
    "ApiKey": "'${API_KEYS[couchpotato]}'",
    "Enabled": true,
    "Ip": "localhost",
    "Port": 5050,
    "SubDir": "couchpotato"
    }' 'http://localhost:3579/request/api/settings/couchpotato?apikey='${API_KEYS[ombi]}''
    echo ""
    echo "-- Updating API Key for Headphones"
    curl -s -X POST --header 'Content-Type: application/json' --header 'Accept: application/json' -d '{
    "ApiKey": "'${API_KEYS[headphones]}'",
    "Enabled": true,
    "Ip": "localhost",
    "Port": 8181,
    "SubDir": "headphones"
    }' 'http://localhost:3579/request/api/settings/headphones?apikey='${API_KEYS[ombi]}''
    echo ""

    if [[ ! $password = "" ]]; then
        echo "-- Updating Password"
        curl -s -X PUT --header 'Content-Type: application/json' --header 'Accept: application/json' -d '{
        "CurrentPassword": "'$oldpassword'",
        "NewPassword": "'$password'"
        }' 'http://localhost:3579/request/api/credentials/openflixr?apikey='${API_KEYS[ombi]}''
    fi

    ## usenet
    echo "- Usenet"
    if [ "$usenetpassword" != '' ]
        then
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
    # echo "- Tautulli (PlexPy)"
    #    if [ "$newznabapi" != '' ]
    #        then
    #         newznab config
    #        else
    #         reverse
    #    fi
    ## tv shows downloader
    echo "- TV Show Downloader"
    if [ "$tvshowdl" == 'sickrage' ]; then
        echo "-- Sickrage"
        curl -s -X POST --header 'Content-Type: application/json' --header 'Accept: application/json' -d '{
        "ApiKey": "'${API_KEYS[sickrage]}'",
        "qualityProfile": "default",
        "Enabled": true,
        "Ip": "localhost",
        "Port": 8081,
        "SubDir": "sickrage"
        }' 'http://localhost:3579/request/api/settings/sickrage?apikey='${API_KEYS[ombi]}''

        sqlite3 database.db "UPDATE setting SET val='on' where key='sickrage_enable';"
        sqlite3 database.db "UPDATE setting SET val='0' where key='sonarr_enable';"
    else
        echo "-- Sonarr"
        curl -s -X POST --header 'Content-Type: application/json' --header 'Accept: application/json' -d '{
        "ApiKey": "'${API_KEYS[sonarr]}'",
        "qualityProfile": "default",
        "Enabled": false,
        "Ip": "localhost",
        "Port": 8081,
        "SubDir": "sickrage"
        }' 'http://localhost:3579/request/api/settings/sickrage?apikey='${API_KEYS[ombi]}''

        sqlite3 database.db "UPDATE setting SET val='0' where key='sickrage_enable';"
        sqlite3 database.db "UPDATE setting SET val='on' where key='sonarr_enable';"
    fi
}