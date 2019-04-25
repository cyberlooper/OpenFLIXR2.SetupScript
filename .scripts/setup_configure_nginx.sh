#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

setup_configure_nginx()
{
    info "Configuring Nginx"
    run_script 'setup_configure_nginx_password'

    info "- Updating Settings"
    crudini --set /usr/share/nginx/html/setup/config.ini network networkconfig ${config[NETWORK]}
    crudini --set /usr/share/nginx/html/setup/config.ini network ip ${config[OPENFLIXR_IP]}
    crudini --set /usr/share/nginx/html/setup/config.ini network subnet ${config[OPENFLIXR_SUBNET]}
    crudini --set /usr/share/nginx/html/setup/config.ini network gateway ${config[OPENFLIXR_GATEWAY]}
    crudini --set /usr/share/nginx/html/setup/config.ini network dns ${config[OPENFLIXR_DNS]}
    crudini --set /usr/share/nginx/html/setup/config.ini access letsencrypt ${config[LETSENCRYPT]}
    crudini --set /usr/share/nginx/html/setup/config.ini access domainname ${config[OPENFLIXR_DOMAIN]}
    crudini --set /usr/share/nginx/html/setup/config.ini access email ${config[OPENFLIXR_EMAIL]}
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
    crudini --set /usr/share/nginx/html/setup/config.ini modules tvshowdl ${config[SERIES_MANAGER]}
    crudini --set /usr/share/nginx/html/setup/config.ini modules nzbdl ${config[NZB_DOWNLOADER]}
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
}
