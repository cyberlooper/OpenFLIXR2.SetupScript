#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

fixes_kernel()
{
    info "Kernel fixes"
    if [[ $(dpkg -l | grep -c linux-generic-hwe-18.04) == 0 ]]; then
        info "- Installing the HWE kernel"
        apt-get -y install --install-recommends linux-generic-hwe-18.04
        warning "- You must reboot your maching after setup completes to get the updated kernel"
        warning "- Reboot using 'sudo reboot' once this has completed"
        sleep 10s
    else
        info "- Kernel fix already applied and nothing to do!"
    fi
    info "- Done"
}