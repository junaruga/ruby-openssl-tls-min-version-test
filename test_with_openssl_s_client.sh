#!/bin/bash

set -euxo pipefail

# Custom
#
# Upstream OpenSSL directory.
OPENSSL_DIR="${HOME}/.local/openssl-3.5.0-dev-fips-debug-d81709316f"
# Domain.
DOMAIN='example.com'

CONFIG_ITEMS="
    tls-12.${DOMAIN}|44333
    tls-13.${DOMAIN}|44334
"
CA_FILE='tmp/test.crt'
LOG_DIR="log/openssl-s_client"
OPENSSL_CLI="${OPENSSL_DIR}/bin/openssl"

rm -rf "${LOG_DIR}"
mkdir -p "${LOG_DIR}"

for item in ${CONFIG_ITEMS}; do
    host="$(echo "${item}" | cut -d '|' -f 1)"
    port="$(echo "${item}" | cut -d '|' -f 2)"

    if ! "${OPENSSL_CLI}" s_client -connect "${host}:${port}" \
        -CAfile "${CA_FILE}" \
        -debug \
        -trace \
        < /dev/null \
        > "${LOG_DIR}/${host}.stdout.log" \
        2> "${LOG_DIR}/${host}.stderr.log"; then
        echo "Failed from ${host}"
    else
        echo "Passed from ${host}"
    fi
done
