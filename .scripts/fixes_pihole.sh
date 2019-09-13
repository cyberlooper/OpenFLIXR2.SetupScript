#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

fixes_pihole()
{
    info "Pi-hole fixes"
    info "- Temporary bypass of pi-hole"
    sed -i "s#nameserver .*#nameserver 8.8.8.8#g" "/etc/resolv.conf"

    if [[ -n "$(command -v dnsmasq)" ]]; then
        info "- dnsmasq found. Removing..."
        service dnsmasq stop
        apt-get -y remove dnsmasq > /dev/null 2>&1 || error "Failed to remove dnsmasq. This will need to be removed for pihole to work correctly."
        rm "/usr/sbin/dnsmasq"
        info "  Removing unused packages."
        apt-get -y autoremove > /dev/null 2>&1 || fatal "Failed to remove unused packages from apt."
        info "  Cleaning up package cache."
        apt-get -y autoclean > /dev/null 2>&1 || fatal "Failed to cleanup cache from apt."
        info "  Done"
        info "- Restarting Pi-hole..."
        service pihole-FTL restart
    fi
    info "- Checking files"
    local FILE="/etc/pihole/dns-servers.conf"
    info "  - ${FILE}"
    if [[ ! -f "${FILE}" ]]; then
        info "    Missing ${FILE}"
        info "    Adding and setting to default values"
        touch "${FILE}"
        echo "Google (ECS);8.8.8.8;8.8.4.4;2001:4860:4860:0:0:0:0:8888;2001:4860:4860:0:0:0:0:8844" >> ${FILE}
        echo "OpenDNS (ECS);208.67.222.222;208.67.220.220;2620:0:ccc::2;2620:0:ccd::2" >> ${FILE}
        echo "Level3;4.2.2.1;4.2.2.2;;" >> ${FILE}
        echo "Comodo;8.26.56.26;8.20.247.20;;" >> ${FILE}
        echo "DNS.WATCH;84.200.69.80;84.200.70.40;2001:1608:10:25:0:0:1c04:b12f;2001:1608:10:25:0:0:9249:d69b" >> ${FILE}
        echo "Quad9 (filtered, DNSSEC);9.9.9.9;149.112.112.112;2620:fe::fe;2620:fe::9" >> ${FILE}
        echo "Quad9 (unfiltered, no DNSSEC);9.9.9.10;149.112.112.10;2620:fe::10;2620:fe::fe:10" >> ${FILE}
        echo "Quad9 (filtered + ECS);9.9.9.11;149.112.112.11;2620:fe::11;" >> ${FILE}
        echo "Cloudflare;1.1.1.1;1.0.0.1;2606:4700:4700::1111;2606:4700:4700::1001" >> ${FILE}
        info "  - Completed!"
    else
        info "  - All good!"
    fi

    info "- Checking Pi-Hole versions"
    PIHOLE_CURRENT=$(pihole -v | grep "Pi-hole" | cut -d ' ' -f 6 | cut -d ')' -f 1)
    PIHOLE_LATEST=$(pihole -v | grep "Pi-hole" | cut -d ' ' -f 8 | cut -d ')' -f 1)
    ADMINLTE_CURRENT=$(pihole -v | grep "AdminLTE" | cut -d ' ' -f 6 | cut -d ')' -f 1)
    ADMINLTE_LATEST=$(pihole -v | grep "AdminLTE" | cut -d ' ' -f 8 | cut -d ')' -f 1)
    FTL_CURRENT=$(pihole -v | grep "FTL" | cut -d ' ' -f 6 | cut -d ')' -f 1)
    FTL_LATEST=$(pihole -v | grep "FTL" | cut -d ' ' -f 8 | cut -d ')' -f 1)
    if [[ ${PIHOLE_LATEST} == "ERROR" || ${ADMINLTE_LATEST} == "ERROR" || ${FTL_LATEST} == "ERROR" ]]; then
        if [[ $(pihole -up | grep -c "Everything is up to date!") -eq 1 ]]; then
            PIHOLE_LATEST=${PIHOLE_CURRENT}
            ADMINLTE_LATEST=${ADMINLTE_CURRENT}
            FTL_LATEST=${FTL_CURRENT}
        fi
    fi
    if [[ ${PIHOLE_CURRENT} != ${PIHOLE_LATEST} || ${ADMINLTE_CURRENT} != ${ADMINLTE_LATEST} || ${FTL_CURRENT} != ${FTL_LATEST} ]]; then
        info "- Pi-Hole needs to be updated..."
        info "  - Changing default binary value"
        sed -i 's/binary="tbd"/binary="pihole-FTL-linux-x86_64"/' "/etc/.pihole/automated install/basic-install.sh"
        info "  - Updating Pi-hole"
        pihole -up
        info "  - Putting the pi-hole install script back to how it should be"
        wget -O "/etc/.pihole/automated install/basic-install.sh" "https://install.pi-hole.net"
        info "  - Verifying versions"
        PIHOLE_CURRENT=$(pihole -v | grep "Pi-hole" | cut -d ' ' -f 6 | cut -d ')' -f 1)
        PIHOLE_LATEST=$(pihole -v | grep "Pi-hole" | cut -d ' ' -f 8 | cut -d ')' -f 1)
        ADMINLTE_CURRENT=$(pihole -v | grep "AdminLTE" | cut -d ' ' -f 6 | cut -d ')' -f 1)
        ADMINLTE_LATEST=$(pihole -v | grep "AdminLTE" | cut -d ' ' -f 8 | cut -d ')' -f 1)
        FTL_CURRENT=$(pihole -v | grep "FTL" | cut -d ' ' -f 6 | cut -d ')' -f 1)
        FTL_LATEST=$(pihole -v | grep "FTL" | cut -d ' ' -f 8 | cut -d ')' -f 1)
        if [[ ${PIHOLE_LATEST} == "ERROR" || ${ADMINLTE_LATEST} == "ERROR" || ${FTL_LATEST} == "ERROR" ]]; then
            if [[ $(pihole -up | grep -c "Everything is up to date!") -eq 1 ]]; then
                PIHOLE_LATEST=${PIHOLE_CURRENT}
                ADMINLTE_LATEST=${ADMINLTE_CURRENT}
                FTL_LATEST=${FTL_CURRENT}
            fi
        fi
        if [[ ${PIHOLE_CURRENT} != ${PIHOLE_LATEST} || ${ADMINLTE_CURRENT} != ${ADMINLTE_LATEST} || ${FTL_CURRENT} != ${FTL_LATEST} ]]; then
            error "    Pi-Hole update not successful =("
            pihole -v
        else
            info "    Pi-Hole updated successfully!"
        fi
    else
        info "- Pi-Hole is up-to-date!"
    fi
    info "- Restarting Pi-hole..."
    service pihole-FTL restart || error "Restart..."
    info "- Undo of the pihole bypass"
    sed -i "s#nameserver .*#nameserver 127.0.0.1#g" "/etc/resolv.conf"
    info "- Done"
}