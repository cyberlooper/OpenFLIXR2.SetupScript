#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

set_config()
{
    config_file="/opt/OpenFLIXR2.SetupScript/openflixr_setup.config"
    key=$1
    val=${2:-}

    config[$key]=$val

    if [[ $(grep -c "$key" $config_file) = 0 ]]; then
        echo "$key=$val" >> $config_file
    else
        sed -i "s#$key=.*#$key=$val #g" $config_file
    fi
}
