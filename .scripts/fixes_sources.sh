#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

fixes_sources()
{
    info "Sources fixes"
    if [[ -f "'/etc/apt/sources.list.d/nijel-ubuntu-phpmyadmin-xenial.list" || -f "/etc/apt/sources.list.d/nijel-ubuntu-phpmyadmin-xenial.list.save" ]]; then
        info "- Removing bad sources (nijel/phpmyadmin)"
        if [[ -f "'/etc/apt/sources.list.d/nijel-ubuntu-phpmyadmin-xenial.list" ]]; then
            rm /etc/apt/sources.list.d/nijel-ubuntu-phpmyadmin-xenial.list
        fi
        if [[ -f "/etc/apt/sources.list.d/nijel-ubuntu-phpmyadmin-xenial.list.save" ]]; then
            rm /etc/apt/sources.list.d/nijel-ubuntu-phpmyadmin-xenial.list.save
        fi
        echo ""
    else
        info "- Nothing to do!"
    fi
    info "- Done"
}