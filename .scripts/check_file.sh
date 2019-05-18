#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

check_file() {
    for (( i=1; i<=30; i++ )); do
        if [[ -f ${1} ]]; then
            log "${2:-}File found: ${1}"
            sleep 1s
            return 0
        fi
        sleep 1s
    done

    log "${2:-}File not found: ${1}"
    return 1
}
