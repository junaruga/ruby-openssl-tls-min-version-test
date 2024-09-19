#!/bin/bash

set -euo pipefail

# Custom
#
# Is the used OpenSSL a downstream OpenSSL RPM?
# false: Use Upstream OpenSSL.
DOWNSTREAM_OPENSSL=true
if [ "${DOWNSTREAM_OPENSSL}" = true ]; then
    # Downstream system OpenSSL.
    OPENSSL_DIR=""
else
    # Upstream OpenSSL directory.
    OPENSSL_DIR="${HOME}/.local/openssl-3.5.0-dev-fips-debug-d81709316f"
fi
# Domain.
DOMAIN='example.com'
# SSL server settings
TLS_1_2_HOST="tls-12.${DOMAIN}"
TLS_1_3_HOST="tls-13.${DOMAIN}"
TLS_1_2_PORT="44333"
TLS_1_3_PORT="44334"
CA_FILE='tmp/test.crt'
LOG_DIR="log/openssl-s_client"
OPENSSL_CLI="${OPENSSL_DIR}/bin/openssl"

function connect_with_openssl_s_client {
    local host="${1}"
    local port="${2}"

    "${OPENSSL_CLI}" s_client -connect "${host}:${port}" \
        -CAfile "${CA_FILE}" \
        -debug \
        -trace \
        < /dev/null \
        > "${LOG_DIR}/${host}.stdout.log" \
        2> "${LOG_DIR}/${host}.stderr.log"
}

rm -rf "${LOG_DIR}"
mkdir -p "${LOG_DIR}"

if [ "${DOWNSTREAM_OPENSSL}" = true ]; then
    if ! grep -q '^TLS.MinProtocol = TLSv1.3$' \
        /etc/crypto-policies/back-ends/opensslcnf.config; then
        echo "[ERROR] The crypto-policies opensslcnf.config TLS.MinProtocol " \
            "should be set as TLSv1.3 for testing." 1>&2
        exit 1
    fi
fi

# The connection to the TLS 1.2 server should fail.
if ! connect_with_openssl_s_client "${TLS_1_2_HOST}" "${TLS_1_2_PORT}"; then
    echo "TLS 1.2 test - OK"
else
    echo "The connection to the TLS 1.2 server should fail " \
        "with the crypto-policies opensslcnf.config TLS.MinProtocol TLSv1.3." \
        1>&2
    exit 2
fi

# The connection to the TLS 1.3 server should pass.
if connect_with_openssl_s_client "${TLS_1_3_HOST}" "${TLS_1_3_PORT}"; then
    echo "TLS 1.3 test - OK"
else
    echo "The connection to the TLS 1.3 server should pass " \
        "with the crypto-policies opensslcnf.config TLS.MinProtocol TLSv1.3." \
        1>&2
    exit 3
fi
