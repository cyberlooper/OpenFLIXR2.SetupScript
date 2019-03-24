#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

step_setup() {
    info 'Preparing for setup...'
    # Set setup variables
    # TODO: Move/rename these at some point
    networkconfig=${config[NETWORK]}
    ip=${config[OPENFLIXR_IP]}
    subnet=${config[OPENFLIXR_SUBNET]}
    gateway=${config[OPENFLIXR_GATEWAY]}
    dns='127.0.0.1'
    password="${OPENFLIXIR_PASSWORD:-}"
    if [[ ${config[ACCESS]} = 'remote' ]]; then
        letsencrypt='on'
        domainname=${config[LETSENCRYPT_DOMAIN]}
        email=${config[LETSENCRYPT_EMAIL]}
    else
        letsencrypt='off'
        domainname=''
        email=''
    fi
    oldpassword=""
    if [[ -f "/usr/share/nginx/html/setup/config.ini" ]]; then
        oldpassword=$(crudini --get /usr/share/nginx/html/setup/config.ini password oldpassword)
    fi
    if [[ "$oldpassword" == "" ]]; then
        oldpassword='openflixr'
    fi
    # TODO: Add these later
    usenetdescription=''
    usenetservername=''
    usenetusername=''
    usenetpassword=''
    usenetport=''
    usenetthreads=''
    usenetssl=''
    newznabprovider=''
    newznaburl=''
    newznabapi=''
    tvshowdl='sickrage' #sickrage or sonarr
    nzbdl='sabnzbd' #sabnzbd or nzbget
    mopidy='enabled'
    hass='enabled'
    ntopng='enabled'
    headphonesuser=''
    headphonespass=''
    anidbuser=''
    anidbpass=''
    spotuser=''
    spotpass=''
    imdb=''
    comicvine=''

    info 'Running setup!'
    run_script 'run_setup'
}
