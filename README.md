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

### Test Ruby OpenSSL built with downstream OpenSSL RPM

OpenSSL RPM package refers to the OS's minimal TLS version setting `TLS.MinProtocol` in the `/etc/crypto-policies/back-ends/opensslcnf.config`.

```
$ rpm -q openssl
openssl-3.1.1-4.fc39.x86_64
```

Compile Ruby OpenSSL with the OpenSSL RPM. Use the Ruby OpenSSL on the latest master branch (https://github.com/ruby/openssl/commit/818aa9fcbb4b041f08b1fa6092dde4729a46214e) compiled with [an OpenSSL 3.3.0-dev](https://github.com/openssl/openssl/commit/1f03d33ef5b1a6657257f983bfba02a7469d846f). This Ruby OpenSSL should respect the OS's minimal TLS

```
$ MAKEFLAGS="V=1" \
  RUBY_OPENSSL_EXTCFLAGS="-O0 -g3 -ggdb3 -gdwarf-5" \
  bundle exec rake compile
```

Test Ruby OpenSSL in some cases. Note you don't need to reboot the OS to update the setting.

```
$ sudo vi /etc/crypto-policies/back-ends/opensslcnf.config

$ grep '^TLS.Min' /etc/crypto-policies/back-ends/opensslcnf.config
TLS.MinProtocol = TLSv1.3

$ ./test.sh
+ ruby -I /home/jaruga/git/ruby/openssl/lib tmp/test.rb
Failed to load from tls-10.example.com: SSL_connect returned=1 errno=0 peeraddr=127.0.0.1:443 state=error: tlsv1 alert protocol version (SSL alert number 70)
Failed to load from tls-11.example.com: SSL_connect returned=1 errno=0 peeraddr=127.0.0.1:443 state=error: tlsv1 alert protocol version (SSL alert number 70)
Failed to load from tls-12.example.com: SSL_connect returned=1 errno=0 peeraddr=127.0.0.1:443 state=error: tlsv1 alert protocol version (SSL alert number 70)
Loaded from tls-13.example.com
```

```
$ sudo vi /etc/crypto-policies/back-ends/opensslcnf.config

$ grep '^TLS.Min' /etc/crypto-policies/back-ends/opensslcnf.config
TLS.MinProtocol = TLSv1.2

$ ./test.sh
+ ruby -I /home/jaruga/git/ruby/openssl/lib tmp/test.rb
Failed to load from tls-10.example.com: SSL_connect returned=1 errno=0 peeraddr=127.0.0.1:443 state=error: tlsv1 alert protocol version (SSL alert number 70)
Failed to load from tls-11.example.com: SSL_connect returned=1 errno=0 peeraddr=127.0.0.1:443 state=error: tlsv1 alert protocol version (SSL alert number 70)
Loaded from tls-12.example.com
Loaded from tls-13.example.com
```

```
$ sudo vi /etc/crypto-policies/back-ends/opensslcnf.config

$ grep '^TLS.Min' /etc/crypto-policies/back-ends/opensslcnf.config
TLS.MinProtocol = TLSv1.1

$ ./test.sh
+ ruby -I /home/jaruga/git/ruby/openssl/lib tmp/test.rb
Failed to load from tls-10.example.com: SSL_connect returned=1 errno=0 peeraddr=127.0.0.1:443 state=error: tlsv1 alert protocol version (SSL alert number 70)
Loaded from tls-11.example.com
Loaded from tls-12.example.com
Loaded from tls-13.example.com
```

```
$ sudo vi /etc/crypto-policies/back-ends/opensslcnf.config

$ grep '^TLS.Min' /etc/crypto-policies/back-ends/opensslcnf.config
TLS.MinProtocol = TLSv1.0

$ ./test.sh
+ ruby -I /home/jaruga/git/ruby/openssl/lib tmp/test.rb
Loaded from tls-10.example.com
Loaded from tls-11.example.com
Loaded from tls-12.example.com
Loaded from tls-13.example.com
```

```
$ sudo vi /etc/crypto-policies/back-ends/opensslcnf.config

$ grep '^TLS.Min' /etc/crypto-policies/back-ends/opensslcnf.config
TLS.MinProtocol = TLSv1

$ ./test.sh
+ ruby -I /home/jaruga/git/ruby/openssl/lib tmp/test.rb
Loaded from tls-10.example.com
Loaded from tls-11.example.com
Loaded from tls-12.example.com
Loaded from tls-13.example.com
```

When testing the Ruby script with tne Ruby OpenSSL applying the reverting commit of [the fixed commit](https://github.com/ruby/openssl/commit/ae215a47ae1a6527bb7b8566e5bcc9430652462f), the test result was below. This was unexpected. Because HTTPD rejected, ignoring the Ruby OpenSSL's request with min_version TLS1 into the HTTPD. It doesn't respect OS's minimal TLS version as expected. Because the Ruby OpenSSL would set the `OpenSSL::SSL::TLS1_VERSION` in the SSL client.

```
$ sudo vi /etc/crypto-policies/back-ends/opensslcnf.config

$ grep '^TLS.Min' /etc/crypto-policies/back-ends/opensslcnf.config
TLS.MinProtocol = TLSv1.3

$ ./test.sh
+ ruby -I /home/jaruga/git/ruby/openssl/lib tmp/test.rb
Loaded from tls-10.example.com
Loaded from tls-11.example.com
Loaded from tls-12.example.com
Loaded from tls-13.example.com
```

### Test Ruby OpenSSL built with upstream OpenSSL

It seems that upstream OpenSSL doesn't refer to the OS's minimal TLS version.

I used the following upstream OpenSSL.

```
$ ~/.local/openssl-3.3.0-dev-fips-debug-1f03d33ef5/bin/openssl version
OpenSSL 3.3.0-dev  (Library: OpenSSL 3.3.0-dev )
```

According to [this article](https://stackoverflow.com/questions/27430158/list-supported-ssl-tls-versions-for-a-specific-openssl-build), below is the command to check the supported TLS versions. This result is same no mater how the value of the `TLS.MinProtocol` in the `/etc/crypto-policies/back-ends/opensslcnf.config`.

```
$ ~/.local/openssl-3.3.0-dev-fips-debug-1f03d33ef5/bin/openssl ciphers -v | awk '{print $2}' | sort | uniq
SSLv3
TLSv1
TLSv1.2
TLSv1.3
```

Compile Ruby OpenSSL with the upstream OpenSSL.

```
$ OPENSSL_DIR="$HOME/.local/openssl-3.3.0-dev-fips-debug-1f03d33ef5"

$ MAKEFLAGS="V=1" \
  RUBY_OPENSSL_EXTCFLAGS="-O0 -g3 -ggdb3 -gdwarf-5" \
  bundle exec rake compile -- \
  --with-openssl-dir="${OPENSSL_DIR}"
```

The test result was below. So, it seems the upstream OpenSSL have own internal minimal TLS version in it.

```
$ grep '^TLS.Min' /etc/crypto-policies/back-ends/opensslcnf.config
TLS.MinProtocol = TLSv1.3

$ ./test.sh
+ ruby -I /home/jaruga/git/ruby/openssl/lib tmp/test.rb
Failed to load from tls-10.example.com: SSL_connect returned=1 errno=0 peeraddr=127.0.0.1:443 state=error: tlsv1 alert protocol version (SSL alert number 70)
Failed to load from tls-11.example.com: SSL_connect returned=1 errno=0 peeraddr=127.0.0.1:443 state=error: tlsv1 alert protocol version (SSL alert number 70)
Loaded from tls-12.example.com
Loaded from tls-13.example.com
```

### Test with downstream OpenSSL RPM openssl s_client

It's convenient to check the SSL connection with the `openssl s_client` instead of Ruby script for debugging purpose.
In this example., I used the `openssl` command in the OpenSSL RPM which refers to the OS's minimal TLS version.

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
### Test with upstream OpenSSL openssl s_client

The following result of the `tmp/test_with_openssl_s_client.sh` shows the upstream OpenSSL has an internal minimal TLS version setting as TLS 1.2.

```
$ grep '^TLS.Min' /etc/crypto-policies/back-ends/opensslcnf.config
TLS.MinProtocol = TLSv1.3

$ ~/.local/openssl-3.3.0-dev-fips-debug-1f03d33ef5/bin/openssl ciphers -v | awk '{print $2}' | sort | uniq
SSLv3
TLSv1
TLSv1.2
TLSv1.3

$ OPENSSL_DIR="$HOME/.local/openssl-3.3.0-dev-fips-debug-1f03d33ef5" \
  tmp/test_with_openssl_s_client.sh
+ DOMAINS='
    tls-10.example.com
    tls-11.example.com
    tls-12.example.com
    tls-13.example.com
'
+ CA_FILE=tmp/test.crt
+ LOG_DIR=log/openssl-s_client
+ OPENSSL_DIR=/home/jaruga/.local/openssl-3.3.0-dev-fips-debug-1f03d33ef5
+ /home/jaruga/.local/openssl-3.3.0-dev-fips-debug-1f03d33ef5=
tmp/test_with_openssl_s_client.sh: line 15: /home/jaruga/.local/openssl-3.3.0-dev-fips-debug-1f03d33ef5=: No such file or directory
+ OPENSSL_CLI=/home/jaruga/.local/openssl-3.3.0-dev-fips-debug-1f03d33ef5/bin/openssl
+ rm -rf log/openssl-s_client
+ mkdir -p log/openssl-s_client
+ for domain in ${DOMAINS}
+ /home/jaruga/.local/openssl-3.3.0-dev-fips-debug-1f03d33ef5/bin/openssl s_client -connect tls-10.example.com:443 -CAfile tmp/test.crt
+ echo 'Failed from tls-10.example.com'
Failed from tls-10.example.com
+ for domain in ${DOMAINS}
+ /home/jaruga/.local/openssl-3.3.0-dev-fips-debug-1f03d33ef5/bin/openssl s_client -connect tls-11.example.com:443 -CAfile tmp/test.crt
+ echo 'Failed from tls-11.example.com'
Failed from tls-11.example.com
+ for domain in ${DOMAINS}
+ /home/jaruga/.local/openssl-3.3.0-dev-fips-debug-1f03d33ef5/bin/openssl s_client -connect tls-12.example.com:443 -CAfile tmp/test.crt
+ echo 'Passed from tls-12.example.com'
Passed from tls-12.example.com
+ for domain in ${DOMAINS}
+ /home/jaruga/.local/openssl-3.3.0-dev-fips-debug-1f03d33ef5/bin/openssl s_client -connect tls-13.example.com:443 -CAfile tmp/test.crt
+ echo 'Passed from tls-13.example.com'
Passed from tls-13.example.com
```
