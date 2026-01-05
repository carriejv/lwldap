#!/bin/bash

set -eo pipefail

LDIF_DIR=/ldif
SLAPD_CFG_DIR=/etc/openldap/slapd.d

function log() {
    echo "[lwldap][$(date)] $1"
}

function should_config() {
    if [ ! -z "${LWLDAP_SKIP_CONFIG}" ]; then
        echo "Skipped config setup due to flag."
        return
    fi
    if [ ! -f "$LDIF_DIR/config.ldif" ]; then
        echo "Skipped config setup because $LDIF_DIR/config.ldif does not exist."
        return
    fi
    if [ -n "$(ls -A $SLAPD_CFG_DIR 2>/dev/null)" ]; then
        echo "Skipped config setup because config already exists."
        return
    fi
}

# debug flag
if [ ! -z "${LWLDAP_DEBUG_STARTUP}" ]; then
    set -x
fi

# config.ldif init
should_config_err="$(should_config)"
if [ -z "$should_config_err" ]; then
    echo "foo"
    exit 99
    slapadd -n 0 -F /etc/openldap/slapd.d/ -l /ldif/config.ldif
else
    log "$should_config_err"
fi
