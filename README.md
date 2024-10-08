# ruby-openssl-tls-min-version-test

This repository is to test Ruby OpenSSL for [this issue fix](https://github.com/ruby/openssl/pull/710).

## Contents

* [How to test](#how-to-test)
  * [With upstream OpenSSL](#with-upstream-openssl)
  * [With downstream OpenSSL RPM](#with-downstream-openssl-rpm)

## How to test

There are 2 cases. The 1st case is with the upstream OpenSSL. The 2nd case is with the downstream (Fedora/CentOS/RHEL) OpenSSL RPM.

In the case of the upstream OpenSSL, as far as I know, there is no logic to override the OpenSSL TLS minimal version setting. So, if the upstream patch is applied, OpenSSL clients should connect to TLS servers without errors.

In the case of the downstream OpenSSL, the way of testing is to run TLS version 1.2 and 1.3 servers on the crypto-policy setting `TLS.MinProtocol = TLSv1.3`, and connect to the servers from OpenSSL clients, the `openssl s_client` command and a Ruby application implemented with Ruby OpenSSL library. The clients should fail to connect to the TLS version 1.2 server, and should succeed to connect to the TLS version 1.3 server under the condition.

The reason why only using TLS version 1.2 and 1.3 servers is because we have to consider the state of the `SECLEVEL` in the `/etc/crypto-policies/back-ends/opensslcnf.config` file for TLS version 1.1 or earlier versions. For example, at the SECLEVEL 1, OpenSSL no longer considers the SHA1-MD5 digest and TLS < 1.2. The signatures using SHA1 and MD5 are also forbidden at this level as they have less than 80 security bits. Additionally, SSLv3, TLS version 1.0, TLS version 1.1 and DTLS version 1.0 are all disabled at this level. This can cause unexpected behaviors in OpenSSL for testing.

### With upstream OpenSSL

Update the following items in the files `setup.sh` and `test_with_openssl_s_client.sh`.

* Update the line `DOWNSTREAM_OPENSSL=true` with `false`.
* Customize the `OPENSSL_DIR` (`OPENSSL_DIR="${HOME}/.local/openssl-3.5.0-dev-fips-debug-d81709316f"`) with your upstream OpenSSL install directory

#### With openssl s_client program

Set up tesing environment running SSL TLS servers with `openssl s_server`.

```
$ ./setup.sh
...
+ /home/jaruga/.local/openssl-3.5.0-dev-fips-debug-d81709316f/bin/openssl s_server -port 44333 -servername tls-12.example.com -tls1_2 -cert ./tmp/test.crt -key ./tmp/test.key -cert2 ./tmp/test.crt -key2 ./tmp/test.key -www -debug -trace
...
+ /home/jaruga/.local/openssl-3.5.0-dev-fips-debug-d81709316f/bin/openssl s_server -port 44334 -servername tls-13.example.com -tls1_3 -cert ./tmp/test.crt -key ./tmp/test.key -cert2 ./tmp/test.crt -key2 ./tmp/test.key -www -debug -trace
...
```

SSL TLS servers are running on the following ports.

```
$ ss -tnl | grep 4433[34]
LISTEN 0      4096               *:44333            *:*
LISTEN 0      4096               *:44334            *:*
```

According to [this article](https://stackoverflow.com/questions/27430158/list-supported-ssl-tls-versions-for-a-specific-openssl-build), below is the command to check the supported TLS versions.

```
$ ~/.local/openssl-3.5.0-dev-fips-debug-d81709316f/bin/openssl ciphers -v | awk '{print $2}' | sort | uniq
SSLv3
TLSv1
TLSv1.2
TLSv1.3
```

Change the downstream OpenSSL flag to the false temporarily to test with upstream OpenSSL.

```
$ sed -i -e '/^DOWNSTREAM_OPENSSL/ s/true/false/' test_with_openssl_s_client.sh
```

Run the following script with the `openssl s_client`. The connections to the TLS 1.2 and 1.3 servers succeed due to no limitation of the TLS version.

```
$ ./test_with_openssl_s_client.sh
TLS 1.2 test - OK
TLS 1.3 test - OK
```

#### With Ruby OpenSSL client program

Compile Ruby OpenSSL with the upstream OpenSSL.

```
$ cd /home/jaruga/git/ruby/openssl

$ OPENSSL_DIR="${HOME}/.local/openssl-3.5.0-dev-fips-debug-d81709316f"

$ MAKEFLAGS="V=1" \
  RUBY_OPENSSL_EXTCFLAGS="-O0 -g3 -ggdb3 -gdwarf-5" \
  bundle exec rake compile -- \
  --with-openssl-dir="${OPENSSL_DIR}"
```

Run the setup script again to run the SSL TLS servers.

```
$ cd /home/jaruga/git/ruby-openssl-tls-min-version-test

$ ./setup.sh
```

SSL TLS servers are running on the following ports.

```
$ ss -tnl | grep 4433[34]
LISTEN 0      4096               *:44333            *:*
LISTEN 0      4096               *:44334            *:*
```

Change the downstream OpenSSL flag to the false temporarily to test with upstream OpenSSL.

```
$ sed -i -e '/^DOWNSTREAM_OPENSSL/ s/true/false/' test.rb
```

The script works.

```
+ ruby -I /home/jaruga/git/ruby/openssl/lib test.rb -v
Loaded suite test
Started
TestRubyOpenSSLTLSMin:
  test_connect_to_tls_1_2_server_on_downstream_openssl:	O
===============================================================================
Omission: omitted. [test_connect_to_tls_1_2_server_on_downstream_openssl(TestRubyOpenSSLTLSMin)]
test.rb:16:in 'TestRubyOpenSSLTLSMin#test_connect_to_tls_1_2_server_on_downstream_openssl'
===============================================================================
: (0.003043)
  test_connect_to_tls_1_2_server_on_upstream_openssl:	.: (0.060088)
  test_connect_to_tls_1_3_server_on_downstream_openssl:	O
===============================================================================
Omission: omitted. [test_connect_to_tls_1_3_server_on_downstream_openssl(TestRubyOpenSSLTLSMin)]
test.rb:34:in 'TestRubyOpenSSLTLSMin#test_connect_to_tls_1_3_server_on_downstream_openssl'
===============================================================================
: (0.002747)
  test_connect_to_tls_1_3_server_on_upstream_openssl:	.: (0.010019)

Finished in 0.077210411 seconds.
-------------------------------------------------------------------------------
4 tests, 2 assertions, 0 failures, 0 errors, 0 pendings, 2 omissions, 0 notifications
100% passed
-------------------------------------------------------------------------------
51.81 tests/s, 25.90 assertions/s
```

### With downstream OpenSSL RPM

See [this instruction document](instructions_downstream.md) first.

#### With openssl s_client program

Set up tesing environment running SSL TLS servers with `openssl s_server`.

```
$ ./setup.sh
```

SSL TLS servers are running on the following ports.

```
$ ss -tnl | grep 4433[34]
LISTEN 0      4096               *:44333            *:*
LISTEN 0      4096               *:44334            *:*
```

Run the following script with the `openssl s_client`. The connection to the TLS 1.2 server fails due to the OS system's minimal TLS protocol version setting `TLS.MinProtocol = TLSv1.3`.

```
$ ./test_with_openssl_s_client.sh
TLS 1.2 test - OK
TLS 1.3 test - OK
```

#### With Ruby OpenSSL client program

Compile Ruby OpenSSL with the upstream OpenSSL.

```
$ cd /home/jaruga/git/ruby/openssl

$ MAKEFLAGS="V=1" \
  RUBY_OPENSSL_EXTCFLAGS="-O0 -g3 -ggdb3 -gdwarf-5" \
  bundle exec rake compile
```

Run the setup script again to run the SSL TLS servers.

```
$ cd /home/jaruga/git/ruby-openssl-tls-min-version-test

$ ./setup.sh
```

SSL TLS servers are running on the following ports.

```
$ ss -tnl | grep 4433[34]
LISTEN 0      4096               *:44333            *:*
LISTEN 0      4096               *:44334            *:*
```

If the Ruby OpenSSL includes the commit <https://github.com/ruby/openssl/commit/ae215a47ae1a6527bb7b8566e5bcc9430652462f>, it respects the OS system's minimal TLS protocol version (`TLS.MinProtocol = TLSv1.3` in this case), and rejects the connection to the TLS 1.2 server as a following result.

```
$ ./test.sh
+ ruby -I /home/jaruga/git/ruby/openssl/lib test.rb -v
Loaded suite test
Started
TestRubyOpenSSLTLSMin:
  test_connect_to_tls_1_2_server_on_downstream_openssl:	.: (0.061572)
  test_connect_to_tls_1_2_server_on_upstream_openssl:	O
===============================================================================
Omission: omitted. [test_connect_to_tls_1_2_server_on_upstream_openssl(TestRubyOpenSSLTLSMin)]
test.rb:26:in 'TestRubyOpenSSLTLSMin#test_connect_to_tls_1_2_server_on_upstream_openssl'
===============================================================================
: (0.002513)
  test_connect_to_tls_1_3_server_on_downstream_openssl:	.: (0.009699)
  test_connect_to_tls_1_3_server_on_upstream_openssl:	O
===============================================================================
Omission: omitted. [test_connect_to_tls_1_3_server_on_upstream_openssl(TestRubyOpenSSLTLSMin)]
test.rb:42:in 'TestRubyOpenSSLTLSMin#test_connect_to_tls_1_3_server_on_upstream_openssl'
===============================================================================
: (0.002364)

Finished in 0.077353526 seconds.
-------------------------------------------------------------------------------
4 tests, 2 assertions, 0 failures, 0 errors, 0 pendings, 2 omissions, 0 notifications
100% passed
-------------------------------------------------------------------------------
51.71 tests/s, 25.86 assertions/s
```

If the Ruby OpenSSL doesn't include the above commit, it doesn't respect the OS system's minimal TLS protocol version, and overrides the setting as TLS version 1 (`OpenSSL::SSL::TLS1_VERSION`). As a result, the connection to the TLS 1.2 server passes as a following result.

```
$ ./test.sh
+ ruby -I /home/jaruga/git/ruby/openssl/lib test.rb -v
Loaded suite test
Started
TestRubyOpenSSLTLSMin:
  test_connect_to_tls_1_2_server_on_downstream_openssl:	F
===============================================================================
Failure: test_connect_to_tls_1_2_server_on_downstream_openssl(TestRubyOpenSSLTLSMin): <OpenSSL::SSL::SSLError> exception was expected but none was thrown.
test.rb:19:in 'TestRubyOpenSSLTLSMin#test_connect_to_tls_1_2_server_on_downstream_openssl'
===============================================================================
: (0.081774)
  test_connect_to_tls_1_2_server_on_upstream_openssl:	O
===============================================================================
Omission: omitted. [test_connect_to_tls_1_2_server_on_upstream_openssl(TestRubyOpenSSLTLSMin)]
test.rb:26:in 'TestRubyOpenSSLTLSMin#test_connect_to_tls_1_2_server_on_upstream_openssl'
===============================================================================
: (0.015299)
  test_connect_to_tls_1_3_server_on_downstream_openssl:	.: (0.011608)
  test_connect_to_tls_1_3_server_on_upstream_openssl:	O
===============================================================================
Omission: omitted. [test_connect_to_tls_1_3_server_on_upstream_openssl(TestRubyOpenSSLTLSMin)]
test.rb:42:in 'TestRubyOpenSSLTLSMin#test_connect_to_tls_1_3_server_on_upstream_openssl'
===============================================================================
: (0.003061)

Finished in 0.113462763 seconds.
-------------------------------------------------------------------------------
4 tests, 2 assertions, 1 failures, 0 errors, 0 pendings, 2 omissions, 0 notifications
50% passed
-------------------------------------------------------------------------------
35.25 tests/s, 17.63 assertions/s
```
