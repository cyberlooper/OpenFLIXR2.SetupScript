#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

step_setup() {
    info 'Preparing for setup...'
    # Set setup variables
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
