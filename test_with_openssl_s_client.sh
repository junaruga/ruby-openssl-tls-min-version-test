#!/bin/bash

set -euxo pipefail

DOMAIN='example.com'

HOSTS="
    tls-10.${DOMAIN}
    tls-11.${DOMAIN}
    tls-12.${DOMAIN}
    tls-13.${DOMAIN}
"
CA_FILE='tmp/test.crt'
LOG_DIR="log/openssl-s_client"

OPENSSL_DIR="${OPENSSL_DIR:-}"
if "${OPENSSL_DIR}" = ''; then
    OPENSSL_CLI='openssl'
else
    OPENSSL_CLI="${OPENSSL_DIR}/bin/openssl"
fi

rm -rf "${LOG_DIR}"
mkdir -p "${LOG_DIR}"

for host in ${HOSTS}; do
    if ! "${OPENSSL_CLI}" s_client -connect "${host}:443" \
        -CAfile "${CA_FILE}" \
        < /dev/null \
        > "${LOG_DIR}/${host}.stdout.log" \
        2> "${LOG_DIR}/${host}.stderr.log"; then
        echo "Failed from ${host}"
    else
        echo "Passed from ${host}"
    fi
done
