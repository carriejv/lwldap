ARG BASEIMG=alpine
ARG BASEIMG_TAG=3.23

FROM ${BASEIMG}:${BASEIMG_TAG}

# Explicitly create an ldap user
ARG LWLDAP_UID=100
ARG LWLDAP_GID=101
ENV LWLDAP_UID=$LWLDAP_UID
ENV LWLDAP_GID=$LWLDAP_GID
RUN addgroup -g "${LWLDAP_GID:-101}" ldap && \
    adduser -DHG ldap -u "${LWLDAP_UID:-100}" -s /usr/sbin/nologin -g "OpenLDAP User" ldap

# Create lwldap flags dir
RUN mkdir -pm 777 /lwldap

# Install openldap
ARG OPENLDAP_VERSION=2.6.10-r0
RUN apk update && \
    apk add envsubst \
    openldap=${OPENLDAP_VERSION} \
    openldap-back-mdb=${OPENLDAP_VERSION} \
    openldap-clients=${OPENLDAP_VERSION}
RUN chown -R ldap:ldap /etc/openldap

# Make default directories
RUN install -m 755 -o ldap -g ldap -d /etc/openldap/slapd.d && \
    install -m 755 -o ldap -g ldap -d /etc/openldap/mdb && \
    install -m 755 -o ldap -g ldap -d /run/openldap

# Expose ldap ports
EXPOSE 389 636

# Copy startup script
COPY ./scripts/lwldap.sh /scripts/lwldap.sh

USER ldap:ldap
ENTRYPOINT ["/scripts/lwldap.sh"]
