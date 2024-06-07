#!/bin/bash
#
# This script is to setup HTTPD with SSL to test the Ruby OpenSSL TLS min
# version.

set -euxo pipefail

# This domaiin is used for SSL cert keys.
# SSL_DOMAIN=${SSL_DOMAIN:-fedoraproject.org}
SSL_DOMAIN=${SSL_DOMAIN:-example.com}

ROOT_DIR="$(dirname "${0}")"
TMP_DIR="${ROOT_DIR}/tmp"
INSTALLED_RPM_PKGS="
    openssl \
    openssl-devel \
    httpd \
    mod_ssl
"
TIMESTAMP_NOW="$(date "+%Y%m%d%H%M%S")"

rm -rf "${TMP_DIR}"
mkdir -p "${TMP_DIR}"

# Install necessary RPM packages.
if ! rpm -q ${INSTALLED_RPM_PKGS} > /dev/null; then
    sudo dnf -y install ${INSTALLED_RPM_PKGS}
    # sudo dnf clean all
fi

# Generate certification keys.
command -v openssl
openssl version

sed -e "s/@DOMAIN@/${SSL_DOMAIN}/g" \
    "${ROOT_DIR}/assets/z-ssl-tls-test.conf.tmpl" \
    > "${TMP_DIR}/z-ssl-tls-test.conf"
openssl genrsa -out "${TMP_DIR}/test.key" 4096
sed -e "s/@DOMAIN@/${SSL_DOMAIN}/g" "${ROOT_DIR}/assets/cert.conf.tmpl" \
    > "${TMP_DIR}/cert.conf"
openssl req -new -key "${TMP_DIR}/test.key" -config "${TMP_DIR}/cert.conf" \
    -out "${TMP_DIR}/test.csr" -sha512 -batch
openssl x509 -req -in "${TMP_DIR}/test.csr" -signkey "${TMP_DIR}/test.key" \
    -out "${TMP_DIR}/test.crt" -sha512

# Generate testing hosts file.
sed -e "s/@DOMAIN@/${SSL_DOMAIN}/g" "${ROOT_DIR}/assets/hosts.tmpl" \
    > "${TMP_DIR}/hosts"

# Generate a testing Ruby script.
sed -e "s/@DOMAIN@/${SSL_DOMAIN}/g" "${ROOT_DIR}/assets/test.rb.tmpl" \
    > "${TMP_DIR}/test.rb"

# Generate a testing Bash script with openssl s_client.
sed -e "s/@DOMAIN@/${SSL_DOMAIN}/g" "${ROOT_DIR}/assets/test_with_openssl_s_client.sh.tmpl" \
    > "${TMP_DIR}/test_with_openssl_s_client.sh"
chmod +x "${TMP_DIR}/test_with_openssl_s_client.sh"

# Deploy the SSL certification keys.
# See the following documents.
# https://docs.fedoraproject.org/en-US/quick-docs/getting-started-with-apache-http-server/#_securing_apache_httpd
# https://fedoraproject.org/wiki/Https#Create_a_certificate_using_OpenSSL
sudo install -m 0600 "${TMP_DIR}/test.crt" /etc/pki/tls/certs/
sudo install -m 0600 "${TMP_DIR}/test.key" /etc/pki/tls/private/
sudo install -m 0600 "${TMP_DIR}/test.csr" /etc/pki/tls/private/
# For SELinux.
restorecon /etc/pki/tls/certs/test.crt
restorecon /etc/pki/tls/private/test.csr
restorecon /etc/pki/tls/private/test.key
# Deploy the testing HTTPD configuration file.
sudo cp -p "${TMP_DIR}/z-ssl-tls-test.conf" \
    /etc/httpd/conf.d/z-ssl-tls-test.conf

if ! grep -E "tls-[0-9]+.${SSL_DOMAIN}" /etc/hosts; then
    # Backup the hosts file just in case.
    sudo cp -p /etc/hosts "/etc/hosts.${TIMESTAMP_NOW}"
    # Append the testing domains.
    cat "${TMP_DIR}/hosts" | sudo tee -a /etc/hosts
    cat /etc/hosts
fi

# Run HTTPD.
sudo systemctl restart httpd.service
systemctl is-active --quiet httpd.service
echo "OK"
