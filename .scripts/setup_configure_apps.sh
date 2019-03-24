#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

setup_configure_apps()
{
    ## nzb downloader
    echo "- NZB Downloader"
    if [ "$nzbdl" == 'sabnzbd' ]; then
        echo "-- SABnzbd"
        sqlite3 /opt/HTPCManager/userdata/database.db "UPDATE setting SET val='on' where key='sabnzbd_enable';"
        sqlite3 /opt/HTPCManager/userdata/database.db "UPDATE setting SET val='0' where key='nzbget_enable';"
    else
        echo "-- NZBget"
        sqlite3 /opt/HTPCManager/userdata/database.db "UPDATE setting SET val='0' where key='sabnzbd_enable';"
        sqlite3 /opt/HTPCManager/userdata/database.db "UPDATE setting SET val='on' where key='nzbget_enable';"
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

    ## letsencrypt
    echo ""
    echo "Configuring Let's Encrypt"
    if [ "$domainname" != '' ]; then
        sudo bash /opt/openflixr/letsencrypt.sh
    fi

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
}