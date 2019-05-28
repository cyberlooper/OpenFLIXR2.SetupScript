#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

setup_configure_letsencrypt()
{
    if [[ "${config[LETSENCRYPT]}" == "on" ]]; then
        info "Backing up nginx configuration"
        cp "/etc/nginx/sites-enabled/openflixr.conf" "/etc/nginx/sites-enabled/openflixr.conf.bak" || error "Could not back up the nginx configuration..."
        info "Configuring Let's Encrypt"
        bash /opt/openflixr/letsencrypt.sh || LETSENCRYPT_STATUS="FAILED"
        if [[ ${LETSENCRYPT_STATUS:-} == "FAILED" ]]; then
            warning "- Let's Encrypt configuration failed! =("
            warning "- Usually this can be fixed later, so we won't kill the setup but will collect some information."
            info "- Adding Let's Encrypt logs to setup logs for troubleshooting"
            if [[ -f "/var/log/letsencrypt.log" ]]; then
                log "- Found Let's Encrypt log file: '/var/log/letsencrypt.log'"
                if [[ $(grep -c "Run pre hook" "/var/log/letsencrypt.log") > 0 ]]; then
                    log "- Found 'Run pre hook' in Let's Encrypt log file!"
                    LE_LOGS_START=$(($(grep -n "Run pre hook" "/var/log/letsencrypt.log" | tail -1 | awk 'BEGIN{FS=":"}{print $(1)}')-1))
                    LE_LOGS_END=$(wc -l "/var/log/letsencrypt.log" | awk '{print $1}')
                    TAIL_COUNT=$(($LE_LOGS_END-$LE_LOGS_START))
                else
                    TAIL_COUNT=25
                    warning "- Could not find 'Run pre hook' in Let's Encrypt log file..."
                    info "- We will get the last ${TAIL_COUNT} lines of the Let's Encrypt log file"
                fi
                debug "TAIL_COUNT=${TAIL_COUNT}"
                tail -${TAIL_COUNT} "/var/log/letsencrypt.log" >> "$LOG_FILE" || error "- Could not get Let's Encrypt logs"
            else
                error "- Could not find Let's Encrypt log file: '/var/log/letsencrypt.log'"
            fi
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

    if [[ "${NGINX_START}" == "Y" ]]; then
        info "Starting nginx..."
        $(service nginx start) || warning "Unable to start nginx"
    fi
}
