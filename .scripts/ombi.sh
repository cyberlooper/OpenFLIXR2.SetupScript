#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

ombi_check() {
    [[ -f /opt/Ombi/complete ]] && info "Ombi Installed." || run_script 'ombi'
}

ombi() {
    echo "ombi start"
    readonly ombidir="/opt/Ombi"
    echo "ombi dir 1"
    if [[ ! -d "${ombidir}" ]]; then
        echo "ombi dir 2"
        mkdir ${ombidir}
        echo "ombi dir 3"
    fi

    echo "ombi get release"
    # From https://github.com/linuxserver/docker-ombi/blob/master/Dockerfile#L22
    #OMBI_RELEASE=$(curl -sX GET "https://api.github.com/repos/tidusjar/Ombi/releases/latest" | awk '/tag_name/{print $4;exit}' FS='[""]')
    #echo "ombi release: ${OMBI_RELEASE}"
    curl -o /tmp/ombi-src.tar.gz -L "https://github.com/tidusjar/Ombi/releases/download/v3.0.5202/linux.tar.gz"
    echo "ombi retrieved?"

    if [[ -f /tmp/ombi-src.tar.gz ]]; then
        echo "ombi retrieved!"
        tar xzf /tmp/ombi-src.tar.gz -C "${ombidir}"
        echo "ombi extracted!"

        chmod +x "${ombidir}/Ombi"
        echo "ombi executable!"

        cd "${ombidir}"
        echo "Should now be in ${ombidir}"
        sleep 5

        apt install -y libicu-dev libunwind8 libcurl4-openssl-dev
        echo "Things installed. Running ombi..."
        '/opt/Ombi/Ombi --storage /opt/Ombi' &
        echo "Ssshhhh... sleeping"
        sleep 60
        echo "Murder..."
        pkill Ombi
        echo "Dead"
        cd "${STORE_PATH}"
        echo "Should now be in ${STORE_PATH}"
    else
        error "Failed to retrieve or extra Ombi"
    fi
    echo "ombi done"
    touch /opt/Ombi/complete
}
