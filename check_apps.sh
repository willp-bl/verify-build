#!/usr/bin/env bash

set -e

ROOT_DIR="$(dirname "$0")"
cd $ROOT_DIR
ROOT_DIR=$(pwd)

check() {
    APP=$1
    PORT=$2
    curl -v http://localhost:$PORT/service-status 2>&1 | grep 200 && printf "%-15s -> %-10s\n" "$APP" "ok" || printf "%-15s -> %-10s\n" "$APP" "not started"
}

curl -v http://localhost:55500/dev.xml > /dev/null 2> /dev/null | grep 200 && echo "metadata ok" || echo "metadata not started"
# add passport stub
curl -v http://localhost:50110/service-name > /dev/null 2> /dev/null | grep policy && echo "policy ok" || echo "policy not started"

check policy 50110
check config 50240
check saml-proxy 50220
check saml-soap-proxy 50160
check stub-event-sink 51100
check saml-engine 50120
check test-rp-msa 50210
#check test-rp 50130
#check stub-idp 50140
check frontend 50300

# check VSP??
#export VSP_PORT=50400
