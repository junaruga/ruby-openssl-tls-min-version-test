#!/bin/bash
#
# This script is to setup HTTPD with SSL to test the Ruby OpenSSL TLS min
# version.

set -euxo pipefail

# Custom
#
# Upstream OpenSSL directory.
OPENSSL_DIR="${HOME}/.local/openssl-3.4.0-dev-fips-debug-d550d2aae5"
# This domaiin is used for SSL cert keys.
# SSL_DOMAIN=${SSL_DOMAIN:-fedoraproject.org}
SSL_DOMAIN=${SSL_DOMAIN:-example.com}

ROOT_DIR="$(dirname "${0}")"
TMP_DIR="${ROOT_DIR}/tmp"
LOG_DIR="log/openssl-s_server"
# INSTALLED_RPM_PKGS="
#     openssl \
#     openssl-devel \
# "
CRYPTO_POLICY="$(update-crypto-policies --show)"
CRYPTO_POLICY_DIR="/usr/share/crypto-policies/${CRYPTO_POLICY}"
TIMESTAMP_NOW="$(date "+%Y%m%d%H%M%S")"

function start_ssl_servers {
    "${OPENSSL_DIR}/bin/openssl" s_server \
        -port 44333 \
        -servername "tls-12.${SSL_DOMAIN}" \
        -tls1_2 \
        -cert "${TMP_DIR}/test.crt" -key "${TMP_DIR}/test.key" \
        -cert2 "${TMP_DIR}/test.crt" -key2 "${TMP_DIR}/test.key" \
        -debug \
        -trace \
        > "${LOG_DIR}/tls-12.${SSL_DOMAIN}.stdout.log" \
        2> "${LOG_DIR}/tls-12.${SSL_DOMAIN}.stderr.log" \
        &
    "${OPENSSL_DIR}/bin/openssl" s_server \
        -port 44334 \
        -servername "tls-13.${SSL_DOMAIN}" \
        -tls1_3 \
        -cert "${TMP_DIR}/test.crt" -key "${TMP_DIR}/test.key" \
        -cert2 "${TMP_DIR}/test.crt" -key2 "${TMP_DIR}/test.key" \
        -debug \
        -trace \
        > "${LOG_DIR}/tls-13.${SSL_DOMAIN}.stdout.log" \
        2> "${LOG_DIR}/tls-13.${SSL_DOMAIN}.stderr.log" \
        &
}

function stop_ssl_servers {
    pkill -f 'openssl s_server' || :
}

function restart_ssl_servers {
    stop_ssl_servers && start_ssl_servers
}

function verify_ssl_servers_are_active {
    ss -tnl | grep 44333
    ss -tnl | grep 44334
}

rm -rf "${TMP_DIR}"
mkdir -p "${TMP_DIR}"

rm -rf "${LOG_DIR}"
mkdir -p "${LOG_DIR}"

# Install necessary RPM packages.
# if ! rpm -q ${INSTALLED_RPM_PKGS} > /dev/null; then
#     sudo dnf -y install ${INSTALLED_RPM_PKGS}
#     # sudo dnf clean all
# fi

# Generate certification keys.
command -v openssl
"${OPENSSL_DIR}/bin/openssl" version

"${OPENSSL_DIR}/bin/openssl" genrsa -out "${TMP_DIR}/test.key" 4096
"${OPENSSL_DIR}/bin/openssl" req -new -key "${TMP_DIR}/test.key" -config "cert.conf" \
    -out "${TMP_DIR}/test.csr" -sha512 -batch
"${OPENSSL_DIR}/bin/openssl" x509 -req -in "${TMP_DIR}/test.csr" -signkey "${TMP_DIR}/test.key" \
    -out "${TMP_DIR}/test.crt" -sha512

# Generate testing hosts file.
sed -e "s/@DOMAIN@/${SSL_DOMAIN}/g" "${ROOT_DIR}/assets/hosts.tmpl" \
    > "${TMP_DIR}/hosts"

if ! grep -E "tls-[0-9]+.${SSL_DOMAIN}" /etc/hosts; then
    # Backup the hosts file just in case.
    sudo cp -p /etc/hosts "/etc/hosts.${TIMESTAMP_NOW}"
    # Append the testing domains.
    cat "${TMP_DIR}/hosts" | sudo tee -a /etc/hosts
    cat /etc/hosts
fi

# At the SECLEVEL 1, OpenSSL no longer considers the SHA1-MD5 digest and
# TLS < 1.2. The signatures using SHA1 and MD5 are also forbidden at this level
# as they have less than 80 security bits. Additionally, SSLv3, TLS 1.0,
# TLS 1.1 and DTLS 1.0 are all disabled at this level.
#
# I don't need to disable SECLEVEL in the TLS 1.2/1.3 cases.
# if ! grep 'SECLEVEL=0' "${CRYPTO_POLICY_DIR}/opensslcnf.txt"; then
#     # Backup the opensslcnf.txt file just in case.
#     sudo cp -p "${CRYPTO_POLICY_DIR}/opensslcnf.txt" \
#         "${CRYPTO_POLICY_DIR}/opensslcnf.txt.${TIMESTAMP_NOW}"
#     sudo sed -i -e 's/SECLEVEL=[1-9]/SECLEVEL=0/' \
#         "${CRYPTO_POLICY_DIR}/opensslcnf.txt"
# fi

# Run SSL servers.
restart_ssl_servers
sleep 1
verify_ssl_servers_are_active

echo "OK"
