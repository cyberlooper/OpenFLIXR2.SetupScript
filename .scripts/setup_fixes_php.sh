#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

setup_fixes_php()
{
    info "PHP fixes"
    info "- Installing new php7.3-fpm"
    export DEBIAN_FRONTEND=noninteractive
    export UCF_FORCE_CONFFNEW=1
    apt-get -y -o Dpkg::Options::=--force-confnew install php7.3-fpm
    export DEBIAN_FRONTEND=
    export UCF_FORCE_CONFFNEW=
    info "- Done"
}