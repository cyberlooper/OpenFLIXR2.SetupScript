#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

setup_configure_nzb_downloader()
{
    info "Configuring NZB Downloader"
    info "- SabNZBd"
    info "  Updating API Key"
    warning "  !No code for updating API Key!"

    info "  Updating settings"
    if [[ $(grep -c "host_whitelist" "/home/openflixr/.sabnzbd/sabnzbd.ini") != 0 ]]; then
        local sabnzbd_current_host_whitelist
        sabnzbd_current_host_whitelist=$(grep -o "host_whitelist = .*" /home/openflixr/.sabnzbd/sabnzbd.ini | sed 's#host_whitelist = ##')
        # OpenFLIXR IP
        if [[ $(grep -c "${config[OPENFLIXR_IP]}" <<<$sabnzbd_current_host_whitelist) = 0 ]]; then
            info "   - Adding '${LOCAL_IP}' to host_whitelist"
            sabnzbd_current_host_whitelist=$sabnzbd_current_host_whitelist"${config[OPENFLIXR_IP]},"
            sed -i 's#host_whitelist = .*#host_whitelist = '$sabnzbd_current_host_whitelist'#' "/home/openflixr/.sabnzbd/sabnzbd.ini"
        fi
        # Domain, if different from OpenFLIXR IP
        if [[ "${config[OPENFLIXR_DOMAIN]}" != "" && $(grep -c "${config[OPENFLIXR_DOMAIN]}" <<<$sabnzbd_current_host_whitelist) = 0 ]]; then
            info "   - Adding '${config[OPENFLIXR_DOMAIN]}' to host_whitelist"
            sabnzbd_current_host_whitelist=$sabnzbd_current_host_whitelist"${config[OPENFLIXR_DOMAIN]},"
            sed -i 's#host_whitelist = .*#host_whitelist = '$sabnzbd_current_host_whitelist'#' "/home/openflixr/.sabnzbd/sabnzbd.ini"
        fi
    fi

    info "  Connecting to Sickrage"
    crudini --set /opt/sickrage/config.ini SABnzbd sab_apikey ${API_KEYS[sabnzbd]}

    # TODO: Look into. I think this might have been messing with people's config...
    # if [ "$usenetpassword" != '' ]; then
    #     info "  Connecting to Usenet"
    #     service sabnzbdplus stop
    #     sleep 5
    #     sed -i 's/^api_key.*/api_key = '1234567890'/' /home/openflixr/.sabnzbd/sabnzbd.ini
    #     service sabnzbdplus start
    #     sleep 5
    #     curl -s 'http://localhost:8080/api?mode=set_config&section=servers&keyword=OpenFLIXR_Usenet_Server&output=xml&enable=1&apikey=1234567890' >> $LOG_FILE
    #     curl -s 'http://localhost:8080/api?mode=set_config&section=servers&keyword=OpenFLIXR_Usenet_Server&output=xml&ssl=$usenetssl&apikey=1234567890' >> $LOG_FILE
    #     curl -s 'http://localhost:8080/api?mode=set_config&section=servers&keyword=OpenFLIXR_Usenet_Server&output=xml&displayname=$usenetdescription&apikey=1234567890' >> $LOG_FILE
    #     curl -s 'http://localhost:8080/api?mode=set_config&section=servers&keyword=OpenFLIXR_Usenet_Server&output=xml&username=$usenetusername&apikey=1234567890' >> $LOG_FILE
    #     curl -s 'http://localhost:8080/api?mode=set_config&section=servers&keyword=OpenFLIXR_Usenet_Server&output=xml&password=$usenetpassword&apikey=1234567890' >> $LOG_FILE
    #     curl -s 'http://localhost:8080/api?mode=set_config&section=servers&keyword=OpenFLIXR_Usenet_Server&output=xml&host=$usenetservername&apikey=1234567890' >> $LOG_FILE
    #     curl -s 'http://localhost:8080/api?mode=set_config&section=servers&keyword=OpenFLIXR_Usenet_Server&output=xml&port=$usenetport&apikey=1234567890' >> $LOG_FILE
    #     curl -s 'http://localhost:8080/api?mode=set_config&section=servers&keyword=OpenFLIXR_Usenet_Server&output=xml&connections=$usenetthreads&apikey=1234567890' >> $LOG_FILE
    #     service sabnzbdplus stop
    #     sed -i 's/^api_key.*/api_key = '${API_KEYS[sabnzbd]}'/' /home/openflixr/.sabnzbd/sabnzbd.ini
    # else
    #     service sabnzbdplus stop
    #     sleep 5
    #     sed -i 's/^api_key.*/api_key = '1234567890'/' /home/openflixr/.sabnzbd/sabnzbd.ini
    #     service sabnzbdplus start
    #     sleep 5
    #     curl -s 'http://localhost:8080/api?mode=set_config&section=servers&keyword=OpenFLIXR_Usenet_Server&output=xml&enable=0&apikey=1234567890' >> $LOG_FILE
    #     service sabnzbdplus stop
    #     sed -i 's/^api_key.*/api_key = '${API_KEYS[sabnzbd]}'/' /home/openflixr/.sabnzbd/sabnzbd.ini
    # fi

    info "- NZBget"
    info "  Updating API Key"
    warning "  !No code for updating API Key!"
}
