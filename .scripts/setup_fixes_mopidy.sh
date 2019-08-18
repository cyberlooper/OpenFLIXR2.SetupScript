#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

setup_fixes_mopidy()
{
    info "Mopidy fixes"
    info "- Updating permissions"
    chown -R mopidy /etc/mopidy
    chmod 0755 /etc/mopidy/mopidy.conf
    info "- Done"
}