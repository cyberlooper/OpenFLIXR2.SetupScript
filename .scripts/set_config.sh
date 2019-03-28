#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

set_config()
{
    key=$1
    val=${2:-}

    config[$key]=$val

    if [[ $(grep -c "$key" $CONFIG_FILE) = 0 ]]; then
        echo "$key=$val" >> $CONFIG_FILE
    else
        sed -i "s#$key=.*#$key=$val #g" $CONFIG_FILE
    fi
}
