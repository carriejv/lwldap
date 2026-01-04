#!/bin/bash

set -euo pipefail

function log() {
    echo "[lwldap][$(date)] - $1"
}

if [ -z "${LWLDAP_DEBUG_STARTUP+1}" ]; then
    set -x
fi

# config.ldif init
if [ -z "${LWLDAP_DEBUG_STARTUP}" ]; then
    slapadd -n 0 -F /etc/openldap/slapd.d/ -l /ldif/config.ldif
else
    log "Skipped config setup due to flag."
fi