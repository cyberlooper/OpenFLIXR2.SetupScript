#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

setup_fixes()
{
    info "Various fixes not handled anywhere else in setup"
    run_script 'fixes_permissions'
    run_script 'fixes_updater'
    run_script 'fixes_mono'
    run_script 'fixes_mopidy'
    run_script 'fixes_nginx'
    run_script 'fixes_php'
    run_script 'fixes_redis'
    run_script 'fixes_sonarr'
    run_script 'fixes_sources'
    run_script 'fixes_pihole'
    run_script 'fixes_kernel'
}