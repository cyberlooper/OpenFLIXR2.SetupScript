#!/bin/bash
exec 1> >(tee -a /var/log/openflixrsetup.log) 2>&1
TODAY=$(date)
echo "-----------------------------------------------------"
echo "Date:          $TODAY"
echo "-----------------------------------------------------"

THISUSER=$(whoami)
    if [ $THISUSER != 'root' ]
        then
            echo 'You must use sudo to run this script, sorry!'
           exit 1
    fi

## variables
networkconfig=
ip=''
subnet=''
gateway=''
dns=''
password=''
letsencrypt=
domainname=
email=
usenetdescription=''
usenetservername=
usenetusername=''
usenetpassword=''
usenetport=
usenetthreads=
usenetssl=
newznabprovider=''
newznaburl=
newznabapi=''
tvshowdl=
nzbdl=
mopidy=
hass=
ntopng=
headphonesuser=''
headphonespass=''
anidbuser=''
anidbpass=''
spotuser=''
spotpass=''
imdb=
comicvine=''

oldpassword=$(crudini --get /usr/share/nginx/html/setup/config.ini password oldpassword)
if [ "$oldpassword" == '' ]
  then
    oldpassword='openflixr'
fi

## stop services
service monit stop
service couchpotato stop
service sickrage stop
service headphones stop
service mylar stop
service sabnzbdplus stop
service jackett stop
service sonarr stop
service radarr stop
service lidarr stop
service lazylibrarian stop
service htpcmanager stop
service mopidy stop
service nzbhydra2 stop

## generate api keys
couchapi=$(uuidgen | tr -d - | tr -d '' | tr '[:upper:]' '[:lower:]')
sickapi=$(uuidgen | tr -d - | tr -d '' | tr '[:upper:]' '[:lower:]')
headapi=$(uuidgen | tr -d - | tr -d '' | tr '[:upper:]' '[:lower:]')
mylapi=$(uuidgen | tr -d - | tr -d '' | tr '[:upper:]' '[:lower:]')
sabapi=$(uuidgen | tr -d - | tr -d '' | tr '[:upper:]' '[:lower:]')
jackapi=$(uuidgen | tr -d - | tr -d '' | tr '[:upper:]' '[:lower:]')
sonapi=$(uuidgen | tr -d - | tr -d '' | tr '[:upper:]' '[:lower:]')
radapi=$(uuidgen | tr -d - | tr -d '' | tr '[:upper:]' '[:lower:]')
lidapi=$(uuidgen | tr -d - | tr -d '' | tr '[:upper:]' '[:lower:]')
lazapi=$(uuidgen | tr -d - | tr -d '' | tr '[:upper:]' '[:lower:]')
nzbhydrapi=$(uuidgen | tr -d - | tr -d '' | tr '[:upper:]' '[:lower:]')
plexpyapi=$(uuidgen | tr -d - | tr -d '' | tr '[:upper:]' '[:lower:]')

echo "Couchpotato $couchapi" >/opt/openflixr/api.keys
echo "Sickrage $sickapi" >>/opt/openflixr/api.keys
echo "Headphones $headapi" >>/opt/openflixr/api.keys
echo "Mylar $mylapi" >>/opt/openflixr/api.keys
echo "SABnzbd $sabapi" >>/opt/openflixr/api.keys
echo "Jackett $jackapi" >>/opt/openflixr/api.keys
echo "Sonarr $sonapi" >>/opt/openflixr/api.keys
echo "Radarr $radapi" >>/opt/openflixr/api.keys
echo "Lidarr $lidapi" >>/opt/openflixr/api.keys
echo "LazyLibrarian $lazapi" >>/opt/openflixr/api.keys
echo "NZBHydra $nzbhydrapi" >>/opt/openflixr/api.keys
echo "PlexPy $plexpyapi" >>/opt/openflixr/api.keys

## htpcmanager
cd /opt/HTPCManager/userdata
sqlite3 database.db "UPDATE setting SET val='$couchapi' where key='couchpotato_apikey';"
sqlite3 database.db "UPDATE setting SET val='$sickapi' where key='sickrage_apikey';"
sqlite3 database.db "UPDATE setting SET val='$headapi' where key='headphones_apikey';"
sqlite3 database.db "UPDATE setting SET val='$mylapi' where key='mylar_apikey';"
sqlite3 database.db "UPDATE setting SET val='$sabapi' where key='sabnzbd_apikey';"
sqlite3 database.db "UPDATE setting SET val='$jackapi' where key='torrents_jackett_apikey';"
sqlite3 database.db "UPDATE setting SET val='$sonapi' where key='sonarr_apikey';"
sqlite3 database.db "UPDATE setting SET val='$radapi' where key='radarr_apikey';"
sqlite3 database.db "UPDATE setting SET val='$plexpyapi' where key='plexpy_apikey';"

## couchpotato
crudini --set /opt/CouchPotato/settings.conf core api_key $couchapi
crudini --set /opt/CouchPotato/settings.conf sabnzbd api_key $sabapi

## sickrage
crudini --set /opt/sickrage/config.ini SABnzbd sab_apikey $sabapi
crudini --set /opt/sickrage/config.ini General api_key $sickapi

## headphones
crudini --set /opt/headphones/config.ini General api_key $headapi
crudini --set /opt/headphones/config.ini SABnzbd sab_apikey $sabapi

## mylar
crudini --set /opt/Mylar/config.ini General api_key $mylapi
crudini --set /opt/Mylar/config.ini SABnzbd sab_apikey $sabapi

## jackett
/root/.config/Jackett/ServerConfig.json
  "APIKey": "03fl3cs2txrxmrvpwmb2sp8b73ko4frl",

## sonarr
sed -i 's/^  <ApiKey>.*/  <ApiKey>'$sonapi'<\/ApiKey>/' /root/.config/NzbDrone/config.xml
Sabnzbd en NZBget API keys invullen, voor alle applicaties

## radarr
sed -i 's/^  <ApiKey>.*/  <ApiKey>'$radapi'<\/ApiKey>/' /root/.config/Radarr/config.xml

## lidarr
sed -i 's/^  <ApiKey>.*/  <ApiKey>'$lidapi'<\/ApiKey>/' /home/openflixr/.config/Lidarr/config.xml

## lazylibrarian
crudini --set /opt/LazyLibrarian/lazylibrarian.ini SABnzbd sab_apikey $sabapi

[USENET]
nzb_downloader_sabnzbd = 1
nzb_downloader_nzbget = 0

## nzbhydra (is dat de enige apiKey?)
/opt/nzbhydra2/data/nzbhydra.yml
  apiKey: "aqpep52c61fkbc8br0tiu53508"

## plexpy
crudini --set /opt/plexpy/config.ini General api_key $plexpyapi

## plexrequests
plexreqapi=$(curl -s -X GET --header 'Accept: application/json' 'http://localhost:3579/request/api/apikey?username=openflixr&password='$oldpassword'' | cut -c10-41)

curl -s -X POST --header 'Content-Type: application/json' --header 'Accept: application/json' -d '{
  "ApiKey": "'$couchapi'",
  "Enabled": true,
  "Ip": "localhost",
  "Port": 5050,
  "SubDir": "couchpotato"
}' 'http://localhost:3579/request/api/settings/couchpotato?apikey='$plexreqapi''
curl -s -X POST --header 'Content-Type: application/json' --header 'Accept: application/json' -d '{
  "ApiKey": "'$headapi'",
  "Enabled": true,
  "Ip": "localhost",
  "Port": 8181,
  "SubDir": "headphones"
}' 'http://localhost:3579/request/api/settings/headphones?apikey='$plexreqapi''
curl -s -X PUT --header 'Content-Type: application/json' --header 'Accept: application/json' -d '{
  "CurrentPassword": "'$oldpassword'",
  "NewPassword": "'$password'"
}' 'http://localhost:3579/request/api/credentials/openflixr?apikey='$plexreqapi''

## usenet
    if [ "$usenetpassword" != '' ]
        then
          service sabnzbdplus stop
          sleep 5
          sed -i 's/^api_key.*/api_key = '1234567890'/' /home/openflixr/.sabnzbd/sabnzbd.ini
          service sabnzbdplus start
          sleep 5
          curl -s 'http://localhost:8080/api?mode=set_config&section=servers&keyword=OpenFLIXR_Usenet_Server&output=xml&enable=1&apikey=1234567890'
          curl -s 'http://localhost:8080/api?mode=set_config&section=servers&keyword=OpenFLIXR_Usenet_Server&output=xml&ssl=&apikey=1234567890'
          curl -s 'http://localhost:8080/api?mode=set_config&section=servers&keyword=OpenFLIXR_Usenet_Server&output=xml&displayname=&apikey=1234567890'
          curl -s 'http://localhost:8080/api?mode=set_config&section=servers&keyword=OpenFLIXR_Usenet_Server&output=xml&username=&apikey=1234567890'
          curl -s 'http://localhost:8080/api?mode=set_config&section=servers&keyword=OpenFLIXR_Usenet_Server&output=xml&password=&apikey=1234567890'
          curl -s 'http://localhost:8080/api?mode=set_config&section=servers&keyword=OpenFLIXR_Usenet_Server&output=xml&host=&apikey=1234567890'
          curl -s 'http://localhost:8080/api?mode=set_config&section=servers&keyword=OpenFLIXR_Usenet_Server&output=xml&port=&apikey=1234567890'
          curl -s 'http://localhost:8080/api?mode=set_config&section=servers&keyword=OpenFLIXR_Usenet_Server&output=xml&connections=&apikey=1234567890'
          service sabnzbdplus stop
          sed -i 's/^api_key.*/api_key = '$sabapi'/' /home/openflixr/.sabnzbd/sabnzbd.ini
    else
          service sabnzbdplus stop
          sleep 5
          sed -i 's/^api_key.*/api_key = '1234567890'/' /home/openflixr/.sabnzbd/sabnzbd.ini
          service sabnzbdplus start
          sleep 5
          curl -s 'http://localhost:8080/api?mode=set_config&section=servers&keyword=OpenFLIXR_Usenet_Server&output=xml&enable=0&apikey=1234567890'
          service sabnzbdplus stop
          sed -i 's/^api_key.*/api_key = '$sabapi'/' /home/openflixr/.sabnzbd/sabnzbd.ini
    fi

## newznab
#    if [ "$newznabapi" != '' ]
#        then
#         newznab config
#        else
#         reverse
#    fi

## tv shows downloader
    if [ "$tvshowdl" == 'sickrage' ]
        then

curl -s -X POST --header 'Content-Type: application/json' --header 'Accept: application/json' -d '{
  "ApiKey": "'$sickapi'",
  "qualityProfile": "default",
  "Enabled": true,
  "Ip": "localhost",
  "Port": 8081,
  "SubDir": "sickrage"
}' 'http://localhost:3579/request/api/settings/sickrage?apikey='$plexreqapi''

    sqlite3 database.db "UPDATE setting SET val='on' where key='sickrage_enable';"
    sqlite3 database.db "UPDATE setting SET val='0' where key='sonarr_enable';"

    else

curl -s -X POST --header 'Content-Type: application/json' --header 'Accept: application/json' -d '{
  "ApiKey": "'$sickapi'",
  "qualityProfile": "default",
  "Enabled": false,
  "Ip": "localhost",
  "Port": 8081,
  "SubDir": "sickrage"
}' 'http://localhost:3579/request/api/settings/sickrage?apikey='$plexreqapi''

    sqlite3 database.db "UPDATE setting SET val='0' where key='sickrage_enable';"
    sqlite3 database.db "UPDATE setting SET val='on' where key='sonarr_enable';"

  fi

## sonarr
service sonarr stop

## nzb downloader
    if [ "$nzbdl" == 'sabnzbd' ]
        then
          sqlite3 database.db "UPDATE setting SET val='on' where key='sabnzbd_enable';"
          sqlite3 database.db "UPDATE setting SET val='0' where key='nzbget_enable';"
    else
          sqlite3 database.db "UPDATE setting SET val='0' where key='sabnzbd_enable';"
          sqlite3 database.db "UPDATE setting SET val='on' where key='nzbget_enable';"
    fi

## headphones vip
    if [ "$headphonespass" != '' ]
        then
          crudini --set /opt/headphones/config.ini General hpuser 
          crudini --set /opt/headphones/config.ini General hppass 
          crudini --set /opt/headphones/config.ini General headphones_indexer 1
          crudini --set /opt/headphones/config.ini General mirror headphones
    else
          crudini --set /opt/headphones/config.ini General hpuser
          crudini --set /opt/headphones/config.ini General hppass
          crudini --set /opt/headphones/config.ini General headphones_indexer 0
          crudini --set /opt/headphones/config.ini General mirror musicbrainz.org
    fi

## anidb
    if [ "$anidbpass" != '' ]
        then
          crudini --set /opt/sickrage/config.ini ANIDB use_anidb 1
          crudini --set /opt/sickrage/config.ini ANIDB anidb_password 
          crudini --set /opt/sickrage/config.ini ANIDB anidb_username 
    else
          crudini --set /opt/sickrage/config.ini ANIDB use_anidb 0
          crudini --set /opt/sickrage/config.ini ANIDB anidb_password
          crudini --set /opt/sickrage/config.ini ANIDB anidb_username
    fi

## spotify mopidy
    if [ "$spotpass" != '' ]
        then
          crudini --set /etc/mopidy/mopidy.conf spotify username 
          crudini --set /etc/mopidy/mopidy.conf spotify password 
    else
          crudini --set /etc/mopidy/mopidy.conf spotify username
          crudini --set /etc/mopidy/mopidy.conf spotify password
    fi

## imdb url
    if [ "$imdb" != '' ]
        then
          crudini --set /opt/CouchPotato/settings.conf imdb automation_urls 
          crudini --set /opt/CouchPotato/settings.conf imdb automation_urls_use 1
    else
          crudini --set /opt/CouchPotato/settings.conf imdb automation_urls
          crudini --set /opt/CouchPotato/settings.conf imdb automation_urls_use 0
    fi

## comicvine
    if [ "$comicvine" != '' ]
        then
          crudini --set /opt/Mylar/config.ini General comicvine_api 
    else
          crudini --set /opt/Mylar/config.ini General comicvine_api
    fi

## spotweb
#users / apikey + passwordhash
#usersettings / id3 / otherprefs | sabnzbd api + password

## passwords
echo openflixr:'' | sudo chpasswd
htpasswd -b /etc/nginx/.htpasswd openflixr ''

## MySQL
#service mysql stop
#killall -vw mysqld
#mysqld_safe --skip-grant-tables >res 2>&1 &
#sleep 10
#mysql -e "UPDATE mysql.user SET authentication_string = PASSWORD('') WHERE User = 'root' AND Host = 'localhost';FLUSH PRIVILEGES;"
#killall -v mysqld
#sleep 5
#service mysql restart
#sed -i "s/^.*\['pass'\].*/\$dbsettings\['pass'\] = 'openflixr';/" /var/www/spotweb/dbsettings.inc.php

## network
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
address 
netmask 
gateway 
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
    if [ "$domainname" != '' ]
        then
          rm -rf /var/log/letsencrypt/
          sed -i 's/^email.*/email = /' /opt/letsencrypt/cli.ini
          sed -i 's/^domains.*/domains = , www./' /opt/letsencrypt/cli.ini
          sed -i 's/check host example.com with address example.com/check host  with address /' /opt/config/monit/certificate
          service nginx stop
          sudo bash /opt/openflixr/letsencrypt.sh
          failed1=$(cat /var/log/letsencrypt/letsencrypt.log | grep "Failed authorization procedure")
          failed2=$(cat /var/log/letsencrypt/letsencrypt.log | grep "is not a FQDN")
            if [ "$failed1" == '' ] && [ "$failed2" == '' ]
            then
                sed -i 's/^server_name.*/server_name openflixr  www.;  #donotremove_domainname/' /etc/nginx/sites-enabled/reverse
                sed -i 's/^.*#donotremove_certificatepath/ssl_certificate \/etc\/letsencrypt\/live\/\/fullchain.pem; #donotremove_certificatepath/' /etc/nginx/sites-enabled/reverse
                sed -i 's/^.*#donotremove_certificatekeypath/ssl_certificate_key \/etc\/letsencrypt\/live\/\/privkey.pem; #donotremove_certificatekeypath/' /etc/nginx/sites-enabled/reverse
                sed -i 's/^.*#donotremove_trustedcertificatepath/ssl_trusted_certificate \/etc\/letsencrypt\/live\/\/fullchain.pem; #donotremove_trustedcertificatepath/' /etc/nginx/sites-enabled/reverse
            else
                echo "Failed authorization procedure or is not a FQDN"
            fi
    else
          sed -i 's/^server_name.*/server_name openflixr;  #donotremove_domainname/' /etc/nginx/sites-enabled/reverse
          sed -i 's/^.*#donotremove_certificatepath/#ssl_certificate \/etc\/letsencrypt\/live\/example\/fullchain.pem; #donotremove_certificatepath/' /etc/nginx/sites-enabled/reverse
          sed -i 's/^.*#donotremove_certificatekeypath/#ssl_certificate_key \/etc\/letsencrypt\/live\/example\/privkey.pem; #donotremove_certificatekeypath/' /etc/nginx/sites-enabled/reverse
          sed -i 's/^.*#donotremove_trustedcertificatepath/#ssl_trusted_certificate \/etc\/letsencrypt\/live\/example\/fullchain.pem; #donotremove_trustedcertificatepath/' /etc/nginx/sites-enabled/reverse
    fi

crudini --set /usr/share/nginx/html/setup/config.ini network networkconfig 
crudini --set /usr/share/nginx/html/setup/config.ini network ip 
crudini --set /usr/share/nginx/html/setup/config.ini network subnet 
crudini --set /usr/share/nginx/html/setup/config.ini network gateway 
crudini --set /usr/share/nginx/html/setup/config.ini network dns 
crudini --set /usr/share/nginx/html/setup/config.ini password oldpassword 
crudini --set /usr/share/nginx/html/setup/config.ini access letsencrypt 
crudini --set /usr/share/nginx/html/setup/config.ini access domainname 
crudini --set /usr/share/nginx/html/setup/config.ini access email 
crudini --set /usr/share/nginx/html/setup/config.ini usenet usenetdescription 
crudini --set /usr/share/nginx/html/setup/config.ini usenet usenetservername 
crudini --set /usr/share/nginx/html/setup/config.ini usenet usenetusername 
crudini --set /usr/share/nginx/html/setup/config.ini usenet usenetpassword 
crudini --set /usr/share/nginx/html/setup/config.ini usenet usenetport 
crudini --set /usr/share/nginx/html/setup/config.ini usenet usenetthreads 
crudini --set /usr/share/nginx/html/setup/config.ini usenet usenetssl 
crudini --set /usr/share/nginx/html/setup/config.ini newznab newznabprovider 
crudini --set /usr/share/nginx/html/setup/config.ini newznab newznaburl 
crudini --set /usr/share/nginx/html/setup/config.ini newznab newznabapi 
crudini --set /usr/share/nginx/html/setup/config.ini modules tvshowdl 
crudini --set /usr/share/nginx/html/setup/config.ini modules nzbdl 
crudini --set /usr/share/nginx/html/setup/config.ini modules mopidy 
crudini --set /usr/share/nginx/html/setup/config.ini modules hass 
crudini --set /usr/share/nginx/html/setup/config.ini modules ntopng 
crudini --set /usr/share/nginx/html/setup/config.ini extras headphonesuser 
crudini --set /usr/share/nginx/html/setup/config.ini extras headphonespass 
crudini --set /usr/share/nginx/html/setup/config.ini extras anidbuser 
crudini --set /usr/share/nginx/html/setup/config.ini extras anidbpass 
crudini --set /usr/share/nginx/html/setup/config.ini extras spotuser 
crudini --set /usr/share/nginx/html/setup/config.ini extras spotpass 
crudini --set /usr/share/nginx/html/setup/config.ini extras imdb 
crudini --set /usr/share/nginx/html/setup/config.ini extras comicvine 
crudini --set /usr/share/nginx/html/setup/config.ini custom custom10 
crudini --set /usr/share/nginx/html/setup/config.ini custom custom11 
crudini --set /usr/share/nginx/html/setup/config.ini custom custom12 
crudini --set /usr/share/nginx/html/setup/config.ini custom custom13 
crudini --set /usr/share/nginx/html/setup/config.ini custom custom14 
crudini --set /usr/share/nginx/html/setup/config.ini custom custom15 
crudini --set /usr/share/nginx/html/setup/config.ini custom custom16 

systemctl --system daemon-reload
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
bash /opt/update/onlineupdate.sh
sed -i 's/<theme>default<\/theme>/<theme>dark<\/theme><insecureSkipHostcheck>true<\/insecureSkipHostcheck>/' /home/openflixr/.config/syncthing/config.xml
sed -i 's/<startBrowser>true<\/startBrowser>/<startBrowser>false<\/startBrowser>/' /home/openflixr/.config/syncthing/config.xml
sed -i 's/<urAccepted>0<\/urAccepted>/<urAccepted>-1<\/urAccepted>/' /home/openflixr/.config/syncthing/config.xml
bash /opt/openflixr/updatewkly.sh
reboot now