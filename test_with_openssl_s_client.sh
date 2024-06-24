#!/bin/bash

set -euxo pipefail

DOMAIN='example.com'
CONFIG_ITEMS="
    tls-12.${DOMAIN}|44333
    tls-13.${DOMAIN}|44334
"
CA_FILE='tmp/test.crt'
LOG_DIR="log/openssl-s_client"

OPENSSL_DIR="${OPENSSL_DIR:-}"
if [ -z "${OPENSSL_DIR}" ]; then
    OPENSSL_CLI='openssl'
else
    OPENSSL_CLI="${OPENSSL_DIR}/bin/openssl"
fi

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
