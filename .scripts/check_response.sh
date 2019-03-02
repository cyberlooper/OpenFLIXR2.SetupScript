#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

check_response() {
    local input=$1

    if [[ $input -eq 1 ]]; then
        echo "'Cancel' selected. Exiting script."
        exit
    fi
}
