#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

setup_fixes_redis()
{
    info "Redis fixes"
    info "- Removing IPv6 binding"
    sed -i "s/bind 127.0.0.1 ::1/bind 127.0.0.1/g" "/etc/redis/redis.conf"
    info "- Done"
}