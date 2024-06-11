# ruby-openssl-tls-min-version-test

This repository is to test Ruby OpenSSL for [this issue fix](https://github.com/ruby/openssl/pull/710).

## How to test

Set up tesing SSL environment with HTTPD.

```
$ ./setup.sh
```

In this example, the testing environment is Fedora 39. I used the following HTTPD and mod_ssl.

```
$ rpm -q httpd mod_ssl
httpd-2.4.59-2.fc39.x86_64
mod_ssl-2.4.59-2.fc39.x86_64
```

Then here is the OS's TLS setting.

```
$ grep '^TLS.Min' /etc/crypto-policies/back-ends/opensslcnf.config
TLS.MinProtocol = TLSv1.2
```

Run a testing Ruby script.

When running the Ruby script with the Ruby OpenSSL on the latest master branch (https://github.com/ruby/openssl/commit/818aa9fcbb4b041f08b1fa6092dde4729a46214e) compiled with [an OpenSSL 3.3.0-dev](https://github.com/openssl/openssl/commit/1f03d33ef5b1a6657257f983bfba02a7469d846f).

```
$ ~/.local/openssl-3.3.0-dev-fips-debug-1f03d33ef5/bin/openssl version
OpenSSL 3.3.0-dev  (Library: OpenSSL 3.3.0-dev )
```

The test result was below. So, it seemed that the Ruby OpenSSL respected the OS security policy.

```
$ ./test.sh
+ ruby -I /home/jaruga/git/ruby/openssl/lib tmp/test.rb
Failed to load from tls-10.example.com: SSL_connect returned=1 errno=0 peeraddr=127.0.0.1:443 state=error: tlsv1 alert protocol version (SSL alert number 70)
Failed to load from tls-11.example.com: SSL_connect returned=1 errno=0 peeraddr=127.0.0.1:443 state=error: tlsv1 alert protocol version (SSL alert number 70)
Loaded from tls-12.example.com
Loaded from tls-13.example.com
```

However, when running the Ruby script with tne Ruby OpenSSL applying the reverting commit of [the fixed commit](https://github.com/ruby/openssl/commit/ae215a47ae1a6527bb7b8566e5bcc9430652462f), the test result was below. This was unexpected. Because HTTPD rejected, ignoring the Ruby OpenSSL's request with min_version TLS1 into the HTTPD.

```
$ ./test.sh
+ ruby -I /home/jaruga/git/ruby/openssl/lib tmp/test.rb
Failed to load from tls-10.example.com: SSL_connect returned=1 errno=0 peeraddr=127.0.0.1:443 state=error: tlsv1 alert protocol version (SSL alert number 70)
Failed to load from tls-11.example.com: SSL_connect returned=1 errno=0 peeraddr=127.0.0.1:443 state=error: tlsv1 alert protocol version (SSL alert number 70)
Loaded from tls-12.example.com
Loaded from tls-13.example.com
```

Run a testing Bash script with the `openssl s_client`.

```
$ grep '^TLS.Min' /etc/crypto-policies/back-ends/opensslcnf.config
TLS.MinProtocol = TLSv1

$ ./tmp/test_with_openssl_s_client.sh
+ DOMAINS='
    tls-10.example.com
    tls-11.example.com
    tls-12.example.com
    tls-13.example.com
'
+ CA_FILE=tmp/test.crt
+ LOG_DIR=log/openssl-s_client
+ rm -rf log/openssl-s_client
+ mkdir -p log/openssl-s_client
+ for domain in ${DOMAINS}
+ openssl s_client -connect tls-10.example.com:443 -CAfile tmp/test.crt
+ echo 'Passed from tls-10.example.com'
Passed from tls-10.example.com
+ for domain in ${DOMAINS}
+ openssl s_client -connect tls-11.example.com:443 -CAfile tmp/test.crt
+ echo 'Passed from tls-11.example.com'
Passed from tls-11.example.com
+ for domain in ${DOMAINS}
+ openssl s_client -connect tls-12.example.com:443 -CAfile tmp/test.crt
+ echo 'Passed from tls-12.example.com'
Passed from tls-12.example.com
+ for domain in ${DOMAINS}
+ openssl s_client -connect tls-13.example.com:443 -CAfile tmp/test.crt
+ echo 'Passed from tls-13.example.com'
Passed from tls-13.example.com
```
