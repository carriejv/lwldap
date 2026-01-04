ARG BASEIMG=debian
ARG BASEIMG_TAG=13.2-slim

FROM ${BASEIMG}:${BASEIMG_TAG}

# Add backports repo for security patches
RUN echo "deb http://ftp.debian.org/debian trixie-backports main" >> /etc/apt/sources.list

# Explicitly create an ldap user 
RUN groupadd -rg "${LWLDAP_GID:-101}" openldap && \
    useradd -rg openldap -u "${LWLDAP_UID:-100}" -s /bin/false -d /usr/sbin/nologin -c "OpenLDAP Server Account" openldap

# Install openldap
ARG OPENLDAP_VERSION=2.6.10\*
RUN LC_ALL=C DEBIAN_FRONTEND=noninteractive apt-get update && \
    apt-get install -y --no-install-recommends \
    ldap-utils=${OPENLDAP_VERSION} \
    slapd=${OPENLDAP_VERSION}

# Make seed ldif directories to ensure they exist
RUN mkdir -p /ldif/ldif.d

# Expose ldap ports
EXPOSE 389 636

ENTRYPOINT /bin/bash
