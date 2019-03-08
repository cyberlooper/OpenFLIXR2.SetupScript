#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

validate_url()
{
    if [[ `wget -S --spider $1  2>&1 | grep 'HTTP/1.1 200 OK'` ]]; then echo "true"; fi
}