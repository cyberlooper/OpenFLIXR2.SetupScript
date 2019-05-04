#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

setup_configure_letsencrypt()
{
    if [[ "${config[LETSENCRYPT]}" == "on" ]]; then
        info "Configuring Let's Encrypt"
        bash /opt/openflixr/letsencrypt.sh || LETSENCRYPT_STATUS="FAILED"
        if [[ ${LETSENCRYPT_STATUS:-} == "FAILED" ]]; then
            warning "Let's Encrypt configuration failed! =("
            warning "Usually this can be fixed later, so we won't kill the setup but will collect some information."
            info "Adding Let's Encrypt logs to setup logs for troubleshooting"
            LE_LOGS_START=$(($(grep -n "Run pre hook" /var/log/letsencrypt.log | tail -1 | awk 'BEGIN{FS=":"}{print $(1)}')-1))
            LE_LOGS_END=$(wc -l /var/log/letsencrypt.log | awk '{print $1}')
            TAIL_COUNT=$(($LE_LOGS_END-$LE_LOGS_START))
            debug "TAIL_COUNT=${TAIL_COUNT}"
            tail -$TAIL_COUNT /var/log/letsencrypt.log >> $LOG_FILE
            info "Checking nginx conf"
            if [[ $(sudo nginx -t 2>&1 | grep -c "failed") != 0 ]]; then
                warning "nginx conf test failed"
                nginx -t 2>&1 >> $LOG_FILE
                warning "nginx cannot run =("
            else
                info "- nginx can still run!"
            fi
        else
            info "Configured!"
        fi
    fi
}
