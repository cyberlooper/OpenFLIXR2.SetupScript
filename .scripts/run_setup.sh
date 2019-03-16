#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

SERVICES=(
    # System Processes
    [monit]=monit
    [htpcmanager]=htpcmanager
    # Apps
    [couchpotato]=couchpotato
    [sickrage]=sickrage
    [headphones]=headphones
    [mylar]=mylar
    [sabnzbd]=sabnzbdplus
    [jackett]=jackett
    [sonarr]=sonarr
    [radarr]=radarr
    [plexpy]=plexpy
    # Apps - other
    [ombi]=ombi
    [lidarr]=lidarr
    [lazylibrarian]=lazylibrarian
    [mopidy]=mopidy
    [nzbhydra2]=nzbhydra2
)
declare -A API_KEYS

run_script 'setup_stop_services'
run_script 'setup_generate_api_keys'

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
## sonarr
service sonarr stop
## nzb downloader
echo "- NZB Downloader"
if [ "$nzbdl" == 'sabnzbd' ]; then
    echo "-- SABnzbd"
    sqlite3 database.db "UPDATE setting SET val='on' where key='sabnzbd_enable';"
    sqlite3 database.db "UPDATE setting SET val='0' where key='nzbget_enable';"
else
    echo "-- NZBget"
    sqlite3 database.db "UPDATE setting SET val='0' where key='sabnzbd_enable';"
    sqlite3 database.db "UPDATE setting SET val='on' where key='nzbget_enable';"
fi
## headphones vip
echo "- Headphones VIP"
if [ "$headphonespass" != '' ]
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
## anidb
echo "- AniDB"
if [ "$anidbpass" != '' ]; then
      crudini --set /opt/sickrage/config.ini ANIDB use_anidb 1
      crudini --set /opt/sickrage/config.ini ANIDB anidb_password $anidbuser
      crudini --set /opt/sickrage/config.ini ANIDB anidb_username $anidbpass
else
      crudini --set /opt/sickrage/config.ini ANIDB use_anidb 0
      crudini --set /opt/sickrage/config.ini ANIDB anidb_password
      crudini --set /opt/sickrage/config.ini ANIDB anidb_username
fi
## spotify mopidy
echo "- Spotify"
if [ "$spotpass" != '' ]; then
      crudini --set /etc/mopidy/mopidy.conf spotify username $spotuser
      crudini --set /etc/mopidy/mopidy.conf spotify password $spotpass
else
      crudini --set /etc/mopidy/mopidy.conf spotify username
      crudini --set /etc/mopidy/mopidy.conf spotify password
fi
## imdb url
echo "- IMDB"
if [ "$imdb" != '' ]
    then
      crudini --set /opt/CouchPotato/settings.conf imdb automation_urls $imdb
      crudini --set /opt/CouchPotato/settings.conf imdb automation_urls_use 1
else
      crudini --set /opt/CouchPotato/settings.conf imdb automation_urls
      crudini --set /opt/CouchPotato/settings.conf imdb automation_urls_use 0
fi
## comicvine
echo "- Compic Vine"
if [ "$comicvine" != '' ]
    then
      crudini --set /opt/Mylar/config.ini General comicvine_api $comicvine
else
      crudini --set /opt/Mylar/config.ini General comicvine_api
fi
## spotweb
#users / apikey + passwordhash
#usersettings / id3 / otherprefs | sabnzbd api + password
## passwords
if [[ ! $password = "" ]]; then
    echo openflixr:"$password" | sudo chpasswd
    htpasswd -b /etc/nginx/.htpasswd openflixr "$password"
fi
## MySQL
#service mysql stop
#killall -vw mysqld
#mysqld_safe --skip-grant-tables >res 2>&1 &
#sleep 10
#mysql -e "UPDATE mysql.user SET authentication_string = PASSWORD('$password') WHERE User = 'root' AND Host = 'localhost';FLUSH PRIVILEGES;"
#killall -v mysqld
#sleep 5
#service mysql restart
#sed -i "s/^.*\['pass'\].*/\\$dbsettings\['pass'\] = 'openflixr';/" /var/www/spotweb/dbsettings.inc.php

## network
echo ""
echo "Configuring network..."
    if [ "$ip" != '' ]
    then
cat > /etc/network/interfaces<<EOF
# This file describes the network interfaces available on your system
# and how to activate them. For more information, see interfaces(5).
source /etc/network/interfaces.d/*
# The loopback network interface
auto lo eth0
iface lo inet loopback
# The primary network interface
iface eth0 inet static
address $ip
netmask $subnet
gateway $gateway
dns-nameservers 127.0.0.1
EOF
    else
cat > /etc/network/interfaces<<EOF
# This file describes the network interfaces available on your system
# and how to activate them. For more information, see interfaces(5).
source /etc/network/interfaces.d/*
# The loopback network interface
auto lo eth0
iface lo inet loopback
# The primary network interface
iface eth0 inet dhcp
dns-nameservers 127.0.0.1
EOF
    fi
## letsencrypt
echo ""
echo "Configuring Let's Encrypt"
if [ "$domainname" != '' ]
    then
      rm -rf /var/log/letsencrypt/
      cp /opt/letsencrypt/cli.ini /opt/letsencrypt/cli.ini.bak
      cp /opt/config/monit/certificate /opt/config/monit/certificate.bak
      sed -i 's/^email.*/email = '$email'/' /opt/letsencrypt/cli.ini
      sed -i 's/^domains.*/domains = '$domainname', www.'$domainname'/' /opt/letsencrypt/cli.ini
      sed -i 's/check host example.com with address example.com/check host '$domainname' with address '$domainname'/' /opt/config/monit/certificate
      service nginx stop
      sudo bash /opt/openflixr/letsencrypt.sh
      failed1=$(cat /var/log/letsencrypt/letsencrypt.log | grep "Failed authorization procedure")
      failed2=$(cat /var/log/letsencrypt/letsencrypt.log | grep "is not a FQDN")
        if [ "$failed1" == '' ] && [ "$failed2" == '' ]
        then
            sed -i 's/^server_name.*/server_name openflixr '$domainname' www.'$domainname';  #donotremove_domainname/' /etc/nginx/sites-enabled/reverse
            sed -i 's/^.*#donotremove_certificatepath/ssl_certificate \/etc\/letsencrypt\/live\/'$domainname'\/fullchain.pem; #donotremove_certificatepath/' /etc/nginx/sites-enabled/reverse
            sed -i 's/^.*#donotremove_certificatekeypath/ssl_certificate_key \/etc\/letsencrypt\/live\/'$domainname'\/privkey.pem; #donotremove_certificatekeypath/' /etc/nginx/sites-enabled/reverse
            sed -i 's/^.*#donotremove_trustedcertificatepath/ssl_trusted_certificate \/etc\/letsencrypt\/live\/'$domainname'\/fullchain.pem; #donotremove_trustedcertificatepath/' /etc/nginx/sites-enabled/reverse
        else
            echo "Failed authorization procedure or is not a FQDN"
            cp /opt/letsencrypt/cli.ini.bak /opt/letsencrypt/cli.ini
            cp /opt/config/monit/certificate.bak /opt/config/monit/certificate
        fi
else
      sed -i 's/^server_name.*/server_name openflixr;  #donotremove_domainname/' /etc/nginx/sites-enabled/reverse
      sed -i 's/^.*#donotremove_certificatepath/#ssl_certificate \/etc\/letsencrypt\/live\/example\/fullchain.pem; #donotremove_certificatepath/' /etc/nginx/sites-enabled/reverse
      sed -i 's/^.*#donotremove_certificatekeypath/#ssl_certificate_key \/etc\/letsencrypt\/live\/example\/privkey.pem; #donotremove_certificatekeypath/' /etc/nginx/sites-enabled/reverse
      sed -i 's/^.*#donotremove_trustedcertificatepath/#ssl_trusted_certificate \/etc\/letsencrypt\/live\/example\/fullchain.pem; #donotremove_trustedcertificatepath/' /etc/nginx/sites-enabled/reverse
fi

echo ""
echo "Updating configurations"
crudini --set /usr/share/nginx/html/setup/config.ini network networkconfig $networkconfig
crudini --set /usr/share/nginx/html/setup/config.ini network ip $ip
crudini --set /usr/share/nginx/html/setup/config.ini network subnet $subnet
crudini --set /usr/share/nginx/html/setup/config.ini network gateway $gateway
crudini --set /usr/share/nginx/html/setup/config.ini network dns $dns
if [[ ! $password = "" ]]; then
    crudini --set /usr/share/nginx/html/setup/config.ini password oldpassword $password
fi
crudini --set /usr/share/nginx/html/setup/config.ini access letsencrypt $letsencrypt
crudini --set /usr/share/nginx/html/setup/config.ini access domainname $domainname
crudini --set /usr/share/nginx/html/setup/config.ini access email $email
crudini --set /usr/share/nginx/html/setup/config.ini usenet usenetdescription $usenetdescription
crudini --set /usr/share/nginx/html/setup/config.ini usenet usenetservername $usenetservername
crudini --set /usr/share/nginx/html/setup/config.ini usenet usenetusername $usenetusername
crudini --set /usr/share/nginx/html/setup/config.ini usenet usenetpassword $usenetpassword
crudini --set /usr/share/nginx/html/setup/config.ini usenet usenetport $usenetport
crudini --set /usr/share/nginx/html/setup/config.ini usenet usenetthreads $usenetthreads
crudini --set /usr/share/nginx/html/setup/config.ini usenet usenetssl $usenetssl
crudini --set /usr/share/nginx/html/setup/config.ini newznab newznabprovider $newznabprovider
crudini --set /usr/share/nginx/html/setup/config.ini newznab newznaburl $newznaburl
crudini --set /usr/share/nginx/html/setup/config.ini newznab newznabapi $newznabapi
crudini --set /usr/share/nginx/html/setup/config.ini modules tvshowdl $tvshowdl
crudini --set /usr/share/nginx/html/setup/config.ini modules nzbdl $nzbdl
crudini --set /usr/share/nginx/html/setup/config.ini modules mopidy $mopidy
crudini --set /usr/share/nginx/html/setup/config.ini modules hass $hass
crudini --set /usr/share/nginx/html/setup/config.ini modules ntopng $ntopng
crudini --set /usr/share/nginx/html/setup/config.ini extras headphonesuser $headphonesuser
crudini --set /usr/share/nginx/html/setup/config.ini extras headphonespass $headphonespass
crudini --set /usr/share/nginx/html/setup/config.ini extras anidbuser $anidbuser
crudini --set /usr/share/nginx/html/setup/config.ini extras anidbpass $anidbpass
crudini --set /usr/share/nginx/html/setup/config.ini extras spotuser $spotuser
crudini --set /usr/share/nginx/html/setup/config.ini extras spotpass $spotpass
crudini --set /usr/share/nginx/html/setup/config.ini extras imdb $imdb
crudini --set /usr/share/nginx/html/setup/config.ini extras comicvine $comicvine
crudini --set /usr/share/nginx/html/setup/config.ini custom custom10 ${API_KEYS[couchpotato]}
crudini --set /usr/share/nginx/html/setup/config.ini custom custom11 ${API_KEYS[sickrage]}
crudini --set /usr/share/nginx/html/setup/config.ini custom custom12 ${API_KEYS[headphones]}
crudini --set /usr/share/nginx/html/setup/config.ini custom custom13 ${API_KEYS[mylar]}
crudini --set /usr/share/nginx/html/setup/config.ini custom custom14 ${API_KEYS[sabnzbd]}
crudini --set /usr/share/nginx/html/setup/config.ini custom custom15 ${API_KEYS[jackett]}
crudini --set /usr/share/nginx/html/setup/config.ini custom custom16 ${API_KEYS[sonarr]}
systemctl --system daemon-reload

#PiHole
echo ""
echo "Updating PiHole"
if [ "$ip" != '' ]
  then
    sed -i 's/IPV4_ADDRESS.*/IPV4_ADDRESS='$ip'/' /etc/pihole/setupVars.conf
    service pihole-FTL restart
    pihole -g -sd
  else
    ip=$(/sbin/ip -o -4 addr list eth0 | awk '{print $4}' | cut -d/ -f1)
    sed -i 's/IPV4_ADDRESS.*/IPV4_ADDRESS='$ip'/' /etc/pihole/setupVars.conf
    service pihole-FTL restart
    pihole -g -sd
fi

#echo ""
#echo "Updating OpenFLIXR"
#bash /opt/update/onlineupdate.sh
#sed -i 's/<theme>default<\/theme>/<theme>dark<\/theme><insecureSkipHostcheck>true<\/insecureSkipHostcheck>/' /home/openflixr/.config/syncthing/config.xml
#sed -i 's/<startBrowser>true<\/startBrowser>/<startBrowser>false<\/startBrowser>/' /home/openflixr/.config/syncthing/config.xml
#sed -i 's/<urAccepted>0<\/urAccepted>/<urAccepted>-1<\/urAccepted>/' /home/openflixr/.config/syncthing/config.xml
#bash /opt/openflixr/updatewkly.sh

echo "System rebooting in about 5 seconds."
sleep 5s
reboot now
