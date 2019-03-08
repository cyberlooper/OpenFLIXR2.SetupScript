#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

install_tzupdate() {
    info "Installing latest tzupdate."
    sudo pip install -U tzupdate || fatal "Failed to install tzupdate from pip."
}