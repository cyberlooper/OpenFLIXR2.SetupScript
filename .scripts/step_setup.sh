#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

step_setup() {
    info 'Preparing for setup...'
    # Set setup variables
    # TODO: Move/rename these at some point
    password="${OPENFLIXIR_PASSWORD:-}"
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
