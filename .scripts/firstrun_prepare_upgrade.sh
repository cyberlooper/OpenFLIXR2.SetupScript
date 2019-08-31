#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

firstrun_prepare_upgrade()
{
    run_script 'load_config'
    if [[ ${UBU_VER} != "18.04" ]]; then
        if [[ ${config[FIRSTRUN_PREPARE_UPGRADE]:-} != "COMPLETED" ]]; then
            info "Preparing for upgrade..."
            apt-get -y update

            info "Upgrading packages. Please be patient, this can take a while..."
            sleep 5s
            RUN_COUNT=0
            while true; do
                log "- Run: ${RUN_COUNT}"
                DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confnew" upgrade && break
                info "Fixing msbuild..."
                for name in /var/cache/apt/archives/msbuild_1%3a16.*_all.deb; do
                    if [[ -f ${name} ]]; then
                        info "- '${name}'"
                        dpkg -i --force-overwrite "${name}" || warning " - An error ocurred fixing msbuild"
                    fi
                done
                info "Installing msbuild"
                DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confnew" install msbuild
                if [[ ${RUN_COUNT} -ge 5 ]]; then
                    error "msbuild has failed to install 5 times now. Exiting..."
                    exit
                fi
                RUN_COUNT=$((RUN_COUNT+1))
            done
            info "Upgrading packages. Please be patient, this can take a while..."
            sleep 5s
            DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confnew" dist-upgrade || fatal "Failed to upgrade packages from apt."
            info "Removing uneeded packages"
            apt-get -y remove ca-certificates-mono libgdiplus libmono-2.0-dev libmono-corlib4.5-cil libmono-i18n4.0-cil libmono-posix4.0-cil libmono-system-configuration4.0-cil libmono-system-core4.0-cil libmono-system-drawing4.0-cil libmono-system-web4.0-cil libmono-system-windows-forms4.0-cil libmono-system4.0-cil libmonoboehm-2.0-1 libmonoboehm-2.0-dev libmonosgen-2.0-1 libmonosgen-2.0-dev mono-4.0-gac mono-gac mono-runtime mono-runtime-common mono-runtime-sgen || warning "Failed to remove one or more packages."
            apt-get -y autoremove
            info "Installing update manager"
            apt-get -y install update-manager-core
            # Make sure release-upgrades is set to LTS
            sed -i 's/Prompt=*/Prompt=lts/g' /etc/update-manager/release-upgrades
            run_script 'set_config' "FIRSTRUN_PREPARE_UPGRADE" "COMPLETED"
        else
            info "Prepare upgrade already completed!"
        fi
    else
        info "System upgrade already completed!"
    fi
}