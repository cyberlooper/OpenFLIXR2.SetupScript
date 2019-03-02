#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

load_config() {
    config_file="${DETECTED_HOMEDIR}/openflixr_setup/openflixr_setup.config"
    shopt -s extglob
    tr -d '\r' < $config_file > $config_file.unix

    while IFS='= ' read -r lhs rhs
    do
        if [[ ! $lhs =~ ^\ *# && -n $lhs ]]; then
            rhs="${rhs%%\#*}"    # Del in line right comments
            rhs="${rhs%%*( )}"   # Del trailing spaces
            rhs="${rhs%\"*}"     # Del opening string quotes 
            rhs="${rhs#\"*}"     # Del closing string quotes 
            config[$lhs]="$rhs"
        fi
    done < $config_file.unix

    rm $config_file.unix
}
