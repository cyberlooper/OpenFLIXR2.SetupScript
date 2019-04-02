#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

setup_configure_book_manager()
{
    info "Configuring Comics Manager"
    info "- Lazylibrarian"
    crudini --set /opt/LazyLibrarian/lazylibrarian.ini SABnzbd sab_apikey ${API_KEYS[sabnzbd]}
}
