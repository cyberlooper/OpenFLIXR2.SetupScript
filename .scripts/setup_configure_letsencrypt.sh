#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

setup_configure_letsencrypt()
{
    local LE_LOG_FILE="/var/log/letsencrypt.log"
    if [[ "${config[LETSENCRYPT]}" == "on" ]]; then
        info "Backing up nginx configuration"
        if [[ -f "/etc/nginx/sites-enabled/openflixr.conf.bak" ]]; then
            mv "/etc/nginx/sites-enabled/openflixr.conf.bak" "${STORE_PATH}/openflixr.conf.bak"
        fi
        cp "/etc/nginx/sites-enabled/openflixr.conf" "${STORE_PATH}/openflixr.conf.bak" || error "Could not back up the nginx configuration..."
        info "Configuring Let's Encrypt"
        bash /opt/openflixr/letsencrypt.sh || LETSENCRYPT_STATUS="FAILED"

        if [[ ${LETSENCRYPT_STATUS:-} == "FAILED" ]]; then
            info "- Checking Let's Encrypt configuration..."

            if [[ -f "${LE_LOG_FILE}" ]]; then
                log "  Found Let's Encrypt log file: '${LE_LOG_FILE}'"
                if [[ $(grep -c "Date:" "${LE_LOG_FILE}") > 0 ]]; then
                    log "  Found 'Date:' in Let's Encrypt log file!"
                    LE_LOGS_START=$(($(grep -n "Date:" "${LE_LOG_FILE}" | tail -1 | awk 'BEGIN{FS=":"}{print $(1)}')-2))
                    if [[ ${LE_LOGS_START} < 0 ]]; then
                        LE_LOGS_START=0
                    fi
                    LE_LOGS_END=$(wc -l "${LE_LOG_FILE}" | awk '{print $1}')
                    TAIL_COUNT=$(($LE_LOGS_END-$LE_LOGS_START))
                else
                    TAIL_COUNT=25
                    log "  Could not find 'Date:' in Let's Encrypt log file..."
                    log "  We will get the last ${TAIL_COUNT} lines of the Let's Encrypt log file"
                fi
                log "  Checking last ${TAIL_COUNT} lines of Let's Encrypt log file for failure indicators..."
                if [[ $(tail -${TAIL_COUNT} "${LE_LOG_FILE}" | grep -c "Domains not changed") != 0 ]]; then
                    LE_DNC=$(tail -${TAIL_COUNT} "${LE_LOG_FILE}" | grep -c "Domains not changed")
                else
                    LE_DNC=0
                fi
                log "  LE_DNC='${LE_DNC}'"

                if [[ $(tail -${TAIL_COUNT} "${LE_LOG_FILE}" | grep -c "Verify error:DNS problem") != 0 ]]; then
                    LE_VE_DNS=$(tail -${TAIL_COUNT} "${LE_LOG_FILE}" | grep -c "Verify error:DNS problem")
                else
                    LE_VE_DNS=0
                fi
                log "  LE_VE_DNS='${LE_VE_DNS}'"

                if [[ $(tail -${TAIL_COUNT} "${LE_LOG_FILE}" | grep -c "Verify error:No valid IP addresses found") != 0 ]]; then
                    LE_VE_IP=$(tail -${TAIL_COUNT} "${LE_LOG_FILE}" | grep -c "Verify error:No valid IP addresses found")
                else
                    LE_VE_IP=0
                fi
                log "  LE_VE_IP='${LE_VE_IP}'"

                if [[ $(tail -${TAIL_COUNT} "${LE_LOG_FILE}" | grep -c "Verify error:Connection refused") != 0 ]]; then
                    LE_VE_CR=$(tail -${TAIL_COUNT} "${LE_LOG_FILE}" | grep -c "Verify error:Connection refused")
                else
                    LE_VE_CR=0
                fi
                log "  LE_VE_CR='${LE_VE_CR}'"

                if [[ ${LE_DNC} > 0 ]]; then
                    info "- Your domains did not change and Let's Encrypt has nothing to do."
                    info "  All good!"
                elif [[ ${LE_VE_DNS} > 0 ]]; then
                    warning "- Your domains couldn't be verified because you are missing a record in your DNS configuration..."
                    warning "  This is either because DNS has not yet propogated or you didn't follow the steps when configuring for Remote Access"
                    warning "  You can run just 'Configure Access' step only after setup completes by choosing 'Configuration' at the Setup Main Menu"
                    sleep 5s
                elif [[ ${LE_VE_IP} > 0 ]]; then
                    warning "- Your domains couldn't be verified because your DNS configuration is not setup properly..."
                    warning "  This is either because DNS has not yet propogated or you didn't follow the steps when configuring for Remote Access"
                    warning "  You can run just 'Configure Access' step only after setup completes by choosing 'Configuration' at the Setup Main Menu"
                    sleep 5s
                elif [[ ${LE_VE_CR} > 0 ]]; then
                    warning "- Your domains couldn't be verified because your Let's Encrypt couldn't connect to your OpenFLIXR server..."
                    warning "  This is usually because you didn't follow the steps when configuring for Remote Access and ports 80 and 443 aren't forwarded to you OpenFLIXR server."
                    warning "  You can run just 'Configure Access' step only after setup completes by choosing 'Configuration' at the Setup Main Menu"
                    sleep 5s
                else
                    log "- And unhandled reason caused Let's Encrypt to fail... =("
                    LE_FAILED="Y"
                fi
            else
                LE_NO_LOGS="Y"
            fi

            if [[ "${LE_FAILED:-}" = "Y" ]]; then
                warning "- Let's Encrypt configuration failed! =("
                warning "  This can be fixed later, so we won't kill the setup but will collect some information."
            elif [[ "${LE_NO_LOGS:-}" = "Y" ]]; then
                error "  Could not find Let's Encrypt log file: '${LE_LOG_FILE}'"
            fi

            if [[ "${LE_FAILED:-}" = "Y" || "${LE_NO_LOGS:-}" = "Y" ]]; then
                info "Checking nginx conf"
                if [[ $(sudo nginx -t 2>&1 | grep -c "failed") != 0 ]]; then
                    warning "- nginx conf test failed. Getting nginx conf test information..."
                    nginx -t 2>&1 >> "$LOG_FILE" || error "- Could not get nginx conf test information"
                    info "- Trying to fix nginx..."
                    if [[ -f "/etc/nginx/sites-enabled/openflixr.conf.bak" ]]; then
                        info "  Restoring backup configuration file..."
                        cp "/etc/nginx/sites-enabled/openflixr.conf.bak" "/etc/nginx/sites-enabled/openflixr.conf"
                    else
                        error "  Could not find backup configuration file to restore =("
                        info "  Disabling SSL in nginx configuration"
                        sed -i 's/^.*#ssl_port_config/#listen 443 ssl http2;	#ssl_port_config/' "/etc/nginx/sites-enabled/openflixr.conf"
                        sed -i 's/^.*#donotremove_certificatepath/#ssl_certificate \/etc\/letsencrypt\/live\/\/fullchain.cer; #donotremove_certificatepath/' "/etc/nginx/sites-enabled/openflixr.conf"
                        sed -i 's/^.*#donotremove_certificatekeypath/#ssl_certificate_key \/etc\/letsencrypt\/live\/\/'$domainname'.key; #donotremove_certificatekeypath/' "/etc/nginx/sites-enabled/openflixr.conf"
                        sed -i 's/^.*#donotremove_trustedcertificatepath/#ssl_trusted_certificate \/etc\/letsencrypt\/live\/\/fullchain.cer; #donotremove_trustedcertificatepath/' "/etc/nginx/sites-enabled/openflixr.conf"
                    fi
                    info "  Checking configuration..."
                    if [[ $(sudo nginx -t 2>&1 | grep -c "failed") != 0 ]]; then
                        error "  - nginx cannot run =("
                        NGINX_START=N
                    else
                        info "  - nginx configuration fixed!"
                        NGINX_START=Y
                    fi
                else
                    info "- nginx can still run!"
                    NGINX_START=Y
                fi
            fi
        else
            info "- Configured!"
            NGINX_START=N
        fi
    else
        info "Not using Let's Encrypt."
        info "Stopping nginx..."
        $(service nginx stop) || warning "Unable to stop nginx"
        info "Making sure SSL is disabled in nginx configuration..."
        sed -i 's/^.*#ssl_port_config/#listen 443 ssl http2;	#ssl_port_config/' "/etc/nginx/sites-enabled/openflixr.conf"
        sed -i 's/^.*#donotremove_certificatepath/#ssl_certificate \/etc\/letsencrypt\/live\/\/fullchain.cer; #donotremove_certificatepath/' "/etc/nginx/sites-enabled/openflixr.conf"
        sed -i 's/^.*#donotremove_certificatekeypath/#ssl_certificate_key \/etc\/letsencrypt\/live\/\/privkey.pem; #donotremove_certificatekeypath/' "/etc/nginx/sites-enabled/openflixr.conf"
        sed -i 's/^.*#donotremove_trustedcertificatepath/#ssl_trusted_certificate \/etc\/letsencrypt\/live\/\/fullchain.cer; #donotremove_trustedcertificatepath/' "/etc/nginx/sites-enabled/openflixr.conf"
        info "Checking configuration..."
        if [[ $(sudo nginx -t 2>&1 | grep -c "failed") != 0 ]]; then
            error "- nginx cannot run =("
            NGINX_START=N
        else
            info "- nginx can run!"
            NGINX_START=Y
        fi
    fi

    if [[ "${NGINX_START:-}" == "Y" ]]; then
        info "Starting nginx..."
        $(service nginx start) || warning "Unable to start nginx"
    fi
}
