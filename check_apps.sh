#!/usr/bin/env bash

set -e

ROOT_DIR="$(dirname "$0")"
cd "$ROOT_DIR"
ROOT_DIR=$(pwd)

check() {
    APP=$1
    PORT=$2
    UPATH="/service-status"
    if [ ! -z "$3" ]; then
        UPATH=$3
    fi
    curl -v "http://localhost:$PORT$UPATH" 2>&1 | grep "HTTP/1.1 200" > /dev/null && printf "%-35s -> %-10s\\n" "$APP" "ok" || printf "%-35s -> %-10s\\n" "$APP" "not started"
}

check metadata 55500 /dev.xml
check policy 50110
check config 50240
check saml-proxy 50220
check saml-soap-proxy 50160
check stub-event-sink 51100
check saml-engine 50120
check test-rp-msa 50210
check vsp-msa 3300
check test-rp 50130
check stub-idp 50140
check frontend 50300
check example-local-matching-service 50500 /version-number
check verify-service-provider 50400 /version-number
check passport-verify-stub-relying-party 3200 /
