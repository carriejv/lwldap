#!/bin/sh

set -eo pipefail

docker build -t lwldap .
docker run -it \
    --env LWLDAP_BIND_DN="cn=root,dc=example,dc=com" \
    --env LWLDAP_BIND_PW="password" \
    --env ROOT_PASSWORD="$(slappasswd -s password)" \
    --env LWLDAP_DEBUG_STARTUP=1 \
    --volume ./test/ldif:/ldif lwldap \
    --name lwldap-test
