#!/bin/sh

# Builds and publishes lwldap
# Usage: ./publish.sh v0.1.0

set -euo pipefail

TARGETS=("latest" "$1")
for tgt in "${TARGETS[@]}"; do
    echo "Building "$tgt"..."
    docker build . -t "carriejv/lwldap:$tgt"
    docker push "carriejv/lwldap:$tgt"
    tgt55="$tgt-55"
    echo "Building "$tgt55"..."
    docker build . --build-arg LWLDAP_UID=55 --build-arg LWLDAP_GID=55 -t "carriejv/lwldap:$tgt55"
    docker push "carriejv/lwldap:$tgt55"
done
