#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

check_dependencies() {
    info "Checking Dependencies..."
    local dependencies=(sed whiptail jq)
    local run_install=0
    for dependency in "${dependencies[@]}"; do
        if [[ -n "$(command -v ${dependency})" ]]; then
            log "${dependency} available"
        else
            error "${dependency} not available."
            run_install=1
        fi
    done

    if [[ ${run_install} == 1 ]]; then
        error "Dependency install needed."
        warning "Run 'sudo setupopenflixr -i' and run setup again."
        exit 0
    fi
}
