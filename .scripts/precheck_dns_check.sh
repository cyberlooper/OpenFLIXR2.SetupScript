#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

precheck_dns_check()
{
    run_script 'load_config'
    local DNS_PASS=1
    if [[ ${config[PRECHECK_DNSCHECK]:-} != "COMPLETED" ]]; then
        info "Doing some basic DNS checks..."
        warning "If any of these fail, you might have issues in the next steps."
        dns_servers_ips=("8.8.8.8" "208.67.222.222" "127.0.0.1" "")
        dns_servers_names=("Google" "OpenDNS" "OpenFLIXR Local Resolution" "OpenFLIXR Auto DNS Resolution")
        websites=("example.com" "google.com" "github.com")

        for dns_server_index in ${!dns_servers_ips[@]}; do
            dns_server_ip=${dns_servers_ips[${dns_server_index}]}
            dns_servers_name=${dns_servers_names[${dns_server_index}]}
            for website in ${websites[@]}; do
                if [[ ${dns_server_ip} == "" ]]; then
                    info "- Checking ${website} via ${dns_servers_name}"
                    dig ${website} > /dev/null
                else
                    info "- Checking ${website} via ${dns_servers_name} (${dns_server_ip})"
                    dig @${dns_server_ip} ${website} > /dev/null
                fi
                return_code=$?
                if [[ ${return_code} -eq 0 ]]; then
                    info "  Good!"
                else
                    DNS_PASS=0
                    case "${return_code}" in
                        1)
                            error "  I messed up..."
                            ;;
                        8)
                            error "  This shouldn't have happened..."
                            ;;
                        9)
                            error "  No reply from server..."
                            ;;
                        10)
                            error "  dig internal error..."
                            ;;
                    esac
                fi
            done
        done
        info "- DNS Check complete"
        if [[ ${DNS_PASS} == 1 ]]; then
            run_script 'set_config' "PRECHECK_DNSCHECK" "COMPLETED"
        fi
    else
        info "DNS Checks already completed!"
    fi
}