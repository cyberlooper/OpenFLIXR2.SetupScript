#!/usr/bin/env bash

readonly ombidir="/opt/ombi"

if [[ ! -d "${ombidir}" ]]; then
    mkdir ${ombidir}
fi

# From https://github.com/linuxserver/docker-ombi/blob/master/Dockerfile#L22
OMBI_RELEASE=$(curl -sX GET "https://api.github.com/repos/tidusjar/Ombi/releases/latest" | awk '/tag_name/{print $4;exit}' FS='[""]');

curl -o /tmp/ombi-src.tar.gz -L "https://github.com/tidusjar/Ombi/releases/download/${OMBI_RELEASE}/linux.tar.gz"

if [[ -f /tmp/ombi-src.tar.gz ]]; then
    tar xzf /tmp/ombi-src.tar.gz -C "${ombidir}"
else
    info "Failed to retrieve or extra Ombi"
fi

chmod +x "${ombidir}/Ombi"

cd ${ombidir}

apt install -y libicu-dev libunwind8 libcurl4-openssl-dev
exec bash "${ombidir}/Ombi" &
sleep 60
pkill Ombi
cd ${STORE_PATH}