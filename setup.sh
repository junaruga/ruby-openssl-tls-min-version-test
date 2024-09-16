#!/bin/bash
#
# This script is to setup HTTPD with SSL to test the Ruby OpenSSL TLS min
# version.

set -euxo pipefail

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
# This domaiin is used for SSL cert keys.
# SSL_DOMAIN=${SSL_DOMAIN:-fedoraproject.org}
SSL_DOMAIN=${SSL_DOMAIN:-example.com}

ROOT_DIR="$(dirname "${0}")"
TMP_DIR="${ROOT_DIR}/tmp"
LOG_DIR="log/openssl-s_server"
INSTALLED_RPM_PKGS="
    openssl \
    openssl-devel \
"
TIMESTAMP_NOW="$(date "+%Y%m%d%H%M%S")"

function start_ssl_servers {
    "${OPENSSL_DIR}/bin/openssl" s_server \
        -port 44333 \
        -servername "tls-12.${SSL_DOMAIN}" \
        -tls1_2 \
        -cert "${TMP_DIR}/test.crt" -key "${TMP_DIR}/test.key" \
        -cert2 "${TMP_DIR}/test.crt" -key2 "${TMP_DIR}/test.key" \
        -www \
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
        -www \
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
if [ "${DOWNSTREAM_OPENSSL}" = true ] && \
    ! rpm -q ${INSTALLED_RPM_PKGS} > /dev/null; then
    sudo dnf -y install ${INSTALLED_RPM_PKGS}
    # sudo dnf clean all
fi

# Generate certification keys.
command -v openssl
"${OPENSSL_DIR}/bin/openssl" version

"${OPENSSL_DIR}/bin/openssl" genrsa -out "${TMP_DIR}/test.key" 4096
"${OPENSSL_DIR}/bin/openssl" req \
    -new \
    -key "${TMP_DIR}/test.key" \
    -config "cert.conf" \
    -out "${TMP_DIR}/test.csr" \
    -sha512 \
    -batch
"${OPENSSL_DIR}/bin/openssl" x509 \
    -req \
    -in "${TMP_DIR}/test.csr" \
    -signkey "${TMP_DIR}/test.key" \
    -out "${TMP_DIR}/test.crt" \
    -sha512

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

# Run SSL servers.
restart_ssl_servers
sleep 1
verify_ssl_servers_are_active

echo "OK"
