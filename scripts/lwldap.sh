#!/bin/sh

set -eo pipefail

LWLDAP_DIR=/lwldap
LDIF_DIR=/ldif
SLAPD_CFG_DIR=/etc/openldap

function log() {
    echo "[lwldap][$(date)] $1"
}

function should_config() {
    if [ ! -z "${LWLDAP_SKIP_CONFIG}" ]; then
        echo "Skipping config setup due to flag."
        return
    fi
    if [ ! -f "$LDIF_DIR/config.ldif" ]; then
        echo "Skipping config setup because $LDIF_DIR/config.ldif does not exist."
        return
    fi
    if [ -d "$SLAPD_CFG_DIR/slapd.d" ] && [ ! -z "$(ls -A "$SLAPD_CFG_DIR/slapd.d" 2>/dev/null)" ]; then
        echo "Skipping config setup because $SLAPD_CFG_DIR/slapd.d already exists and contains config."
        return
    fi
    if [ -f "$LWLDAP_DIR/.lwldap_config_done" ]; then
        echo "Skipping config setup because it has already completed once."
        return
    fi
}

function should_seed() {
    if [ ! -z "${LWLDAP_SKIP_SEED}" ]; then
        echo "Skipping db seed due to flag."
        return
    fi
    if [ -z "${LWLDAP_BIND_DN}" ]; then
        echo "Skipping db seed due to missing bind user."
        return
    fi
    if [ -z "${LWLDAP_BIND_PW}" ]; then
        echo "Skipping db seed due to missing bind password."
        return
    fi
    if [ ! -d "$LDIF_DIR/ldif.d" ]; then
        echo "Skipping db seed because $LDIF_DIR/ldif.d does not exist."
        return
    fi
    if [ -z "$(ls -A "$LDIF_DIR/ldif.d" 2>/dev/null)" ]; then
        echo "Skipping db seed because $LDIF_DIR/ldif.d is empty."
        return
    fi
    if [ -f "$LWLDAP_DIR/.lwldap_seed_done" ]; then
        echo "Skipping db seed because it has already completed once."
        return
    fi
}

function substitute() {
    tmp="$(mktemp)"
    cat "$1" | envsubst > "$tmp"
    echo "$tmp"
}

function ldap_add() {
    file="$(substitute "$1")"
    ldapadd -H "ldap://localhost" \
        -D "$LWLDAP_BIND_DN" \
        -w "$LWLDAP_BIND_PW" \
        -f "$file" || true
}

function ldap_modify() {
    file="$(substitute "$1")"
    ldapmodify -H "ldap://localhost" \
        -D "$LWLDAP_BIND_DN" \
        -w "$LWLDAP_BIND_PW" \
        -f "$file" || true
}

function db_seed() {
    # Wait until slapd spinup is complete
    until ldapwhoami -D "$LWLDAP_BIND_DN" -w "$LWLDAP_BIND_PW" 2>&1 > /dev/null; do
        sleep 1
    done
    for ldif_file in $LDIF_DIR/ldif.d/*.ldif; do
        log "Processing $ldif_file..."
        if [ "$LWLDAP_SEED_METHOD" = "add" ]; then
            ldap_add "$ldif_file"
        elif [ "$LWLDAP_SEED_METHOD" = "modify" ]; then
            ldap_modify "$ldif_file"
        else
            has_modify=0
            if grep -qi "^\s*changeType:" "$ldif_file"; then
                has_modify=1
            fi
            if [[ $has_modify -eq 1 ]]; then
                ldap_modify "$ldif_file"
            else
                ldap_add "$ldif_file"
            fi
        fi
    done
}

# debug flag
if [ ! -z "${LWLDAP_DEBUG_STARTUP}" ]; then
    set -x
fi

# config.ldif init
should_config_err="$(should_config)"
if [ -z "$should_config_err" ]; then
    log "Adding config.ldif..."
    rm -f "$SLAPD_CFG_DIR/slapd.ldif" || true
    rm -f "$SLAPD_CFG_DIR/slapd.conf" || true
    file="$(substitute /ldif/config.ldif)"
    slapadd -n 0 -F "$SLAPD_CFG_DIR/slapd.d" -l "$file"
    touch "$LWLDAP_DIR/.lwldap_config_done"
else
    log "$should_config_err"
fi

# fork db seeder
# to allow lwldap.sh to remain pid 1
should_seed_err="$(should_seed)"
if [ -z "$should_seed_err" ]; then
    log "Seeding database with /ldif/ldif.d files..."
    db_seed &
    touch "$LWLDAP_DIR/.lwldap_seed_done"
else
    log "$should_seed_err"
fi

# start slapd
log "Starting slapd..."
pkill slapd || true
rm -rf /tmp/*
slapd -u ldap -h "ldap:/// ldaps:///" -d "${LWLDAP_SLAPD_LOG_LEVEL:-256}"
