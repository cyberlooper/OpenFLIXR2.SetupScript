#!/bin/bash

#Helper methods
function check_cancel()
{
    local input=$1
    
    if [[ $input -eq 1 ]]; then
        echo "'Cancel' selected. Exiting script."
        exit
    fi
}

function valid_ip()
{
    local  ip=$1
    local  stat=1

    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        OIFS=$IFS
        IFS='.'
        ip=($ip)
        IFS=$OIFS
        [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 \
            && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
        stat=$?
    fi
    return $stat
}

function validate_url()
{
    if [[ `wget -S --spider $1  2>&1 | grep 'HTTP/1.1 200 OK'` ]]; then echo "true"; fi
}

function set_config()
{
    key=$1
    val=$2
    
    config[$key]=$val

    if [[ $(grep -c "$key" $OPENFLIXR_SETUP_CONFIG) = 0 ]]; then
        echo "$key=$val" >> $OPENFLIXR_SETUP_CONFIG
    else
        sed -i "s/$key=.*/$key=$val /g" $OPENFLIXR_SETUP_CONFIG
    fi
}

function save_config()
{
    for KEY in "${!config[@]}"; do 
        set_config "${KEY}" ${config[$KEY]}
    done
}

function load_config()
{
    config_file=$1
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