#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

check_application_ready() {
    for (( i=1; i<=30; i++ )); do
        status=$(curl -sL -w "%{http_code}\\n" "http://localhost:3579/request" -o /dev/null)
        if [[ $status = "200" ]]; then
            log "Received ${status} from ${1}"
            sleep 1s
            return "${status}"
        fi
        sleep 1s
    done

    log "Received ${status} from ${1}"
    return "${status}"
}
