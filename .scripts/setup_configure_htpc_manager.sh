#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

setup_configure_htpc_manager()
{
    info "Configuring HTPC Manager"
    if [[ ! -f "/opt/HTPCManager/userdata/database.db" ]]; then
        info "- Failed to find HTPC Manager DB file. Trying to have HTPC Manager generate it..."
        info "  Starting HTPC Manager"
        service htpcmanager start || error "Unable to start HTPC Manager"
        sleep 5s
        if [[ $(run_script 'check_file' "/opt/HTPCManager/userdata/database.db" "  ") == "200" ]]; then
            info "  HTPC Manager DB file found!"
        else
            error "  HTPC Manager DB file still could not be found..."
        fi
        sleep 5s
        info "  Stopping HTPC Manager"
        service htpcmanager stop || error "Unable to start HTPC Manager"
    fi
    if [[ -f "/opt/HTPCManager/userdata/database.db" ]]; then
        for service in "${!API_KEYS[@]}"; do
            if [[ "${service}" != "monit"
                && "${service}" != "htpcmanager"
                && "${service}" != "lidarr"
                && "${service}" != "lazylibrarian"
                && "${service}" != "mopidy"
                && "${service}" != "nzbhydra2"
            ]]; then
                info "- ${service}"
                info "  Updating API key"
                if [[ "${service}" == "jackett" ]]; then
                    if [[ $(sqlite3 /opt/HTPCManager/userdata/database.db "SELECT COUNT(id) FROM setting WHERE key='torrents_${service}_apikey'") != 1 ]]; then
                        warning "Multiple entries found for 'torrents_${service}_apikey'. Removing all entries..."
                        sqlite3 /opt/HTPCManager/userdata/database.db "DELETE FROM setting WHERE key='torrents_${service}_apikey'"
                    fi
                    sqlite3 /opt/HTPCManager/userdata/database.db "INSERT OR REPLACE INTO setting (id, key, val)
                                                        VALUES (  (SELECT id FROM setting WHERE key='torrents_${service}_apikey'),
                                                                'torrents_${service}_apikey',
                                                                '${API_KEYS[$service]}'
                                                            );"
                else
                    if [[ $(sqlite3 /opt/HTPCManager/userdata/database.db "SELECT COUNT(id) FROM setting WHERE key='${service}_apikey'") != 1 ]]; then
                        warning "Multiple entries found for '${service}_apikey'. Removing all entries..."
                        sqlite3 /opt/HTPCManager/userdata/database.db "DELETE FROM setting WHERE key='${service}_apikey'"
                    fi
                    sqlite3 /opt/HTPCManager/userdata/database.db "INSERT OR REPLACE INTO setting (id, key, val)
                                                        VALUES (  (SELECT id FROM setting WHERE key='${service}_apikey'),
                                                                '${service}_apikey',
                                                                '${API_KEYS[$service]}'
                                                            );"
                    # Series & Movie managers
                    if [[ "${service}" == "sonarr"
                        || "${service}" == "sickrage"
                        || "${service}" == "radarr"
                        || "${service}" == "couchpotato"
                        || "${service}" == "sabnzbd"
                        || "${service}" == "nzbget"
                    ]]; then
                        local ENABLED_HTPC
                        if [[ "${config[SERIES_MANAGER]}" == "${service}" 
                            || "${config[MOVIE_MANAGER]}" == "${service}"
                            || "${config[NZB_DOWNLOADER]}" == "${service}"
                        ]]; then
                            info "  Enabling in HTPC"
                            ENABLED_HTPC="on"
                        else
                            info "  Disabling in HTPC"
                            ENABLED_HTPC="0"
                        fi

                        sqlite3 /opt/HTPCManager/userdata/database.db "INSERT OR REPLACE INTO setting (id, key, val)
                                                                        VALUES (  (SELECT id FROM setting WHERE key='${service}_enable'),
                                                                                '${service}_enable',
                                                                                '${ENABLED_HTPC}'
                                                                            );"
                    fi

                    if [[ "${service}" == "ombi" ]]; then
                        log "  Enabling in HTPC"
                        log "  - ombi_enable"
                        sqlite3 /opt/HTPCManager/userdata/database.db "INSERT OR REPLACE INTO setting (id, key, val)
                                                                        VALUES (  (SELECT id FROM setting WHERE key='ombi_enable'),
                                                                                'ombi_enable',
                                                                                'on'
                                                                            );"
                        log "  - ombi_name"
                        sqlite3 /opt/HTPCManager/userdata/database.db "INSERT OR REPLACE INTO setting (id, key, val)
                                                                        VALUES (  (SELECT id FROM setting WHERE key='ombi_name'),
                                                                                'ombi_name',
                                                                                'Ombi'
                                                                            );"
                        log "  - ombi_host"
                        sqlite3 /opt/HTPCManager/userdata/database.db "INSERT OR REPLACE INTO setting (id, key, val)
                                                                        VALUES (  (SELECT id FROM setting WHERE key='ombi_host'),
                                                                                'ombi_host',
                                                                                'localhost'
                                                                            );"
                        log "  - ombi_port"
                        sqlite3 /opt/HTPCManager/userdata/database.db "INSERT OR REPLACE INTO setting (id, key, val)
                                                                        VALUES (  (SELECT id FROM setting WHERE key='ombi_port'),
                                                                                'ombi_port',
                                                                                '3579'
                                                                            );"
                        log "  - ombi_username"
                        sqlite3 /opt/HTPCManager/userdata/database.db "INSERT OR REPLACE INTO setting (id, key, val)
                                                                        VALUES (  (SELECT id FROM setting WHERE key='ombi_username'),
                                                                                'ombi_username',
                                                                                'openflixr'
                                                                            );"
                        local OMBI_PASSWORD
                        if [[ ${config[CHANGE_PASS]} == "Y" && ${OPENFLIXR_PASSWORD_NEW} != "" ]]; then
                            OMBI_PASSWORD=${OPENFLIXR_PASSWORD_NEW}
                        else
                            OMBI_PASSWORD=${OPENFLIXR_PASSWORD_OLD}
                        fi

                        sqlite3 /opt/HTPCManager/userdata/database.db "INSERT OR REPLACE INTO setting (id, key, val)
                                                                        VALUES (  (SELECT id FROM setting WHERE key='ombi_password'),
                                                                                'ombi_password',
                                                                                '${OMBI_PASSWORD}'
                                                                            );"
                    fi
                fi
            fi
        done
    else
        error "- HTPC Manager DB file not available..."
        warning "  You will need to try to run this step again later or configure HTPC Manager manually."
    fi
}
