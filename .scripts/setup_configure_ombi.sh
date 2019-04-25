#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

setup_configure_ombi()
{
    info "Configuring Ombi"
    run_script 'setup_configure_ombi_password'
}
