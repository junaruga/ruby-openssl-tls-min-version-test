# ruby-openssl-tls-min-version-test

This repository is to test Ruby OpenSSL for [this issue fix](https://github.com/ruby/openssl/pull/710).

## How to test

### With Upstream OpenSSL

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

Run the following script with the `openssl s_client`. The connections to the TLS 1.2 and 1.3 servers succeed due to no limitation of the TLS version.

```
$ ./test_with_openssl_s_client.sh
...
+ /home/jaruga/.local/openssl-3.5.0-dev-fips-debug-d81709316f/bin/openssl s_client -connect tls-12.example.com:44333 -CAfile tmp/test.crt -debug -trace
+ echo 'Passed from tls-12.example.com'
Passed from tls-12.example.com
...
+ /home/jaruga/.local/openssl-3.5.0-dev-fips-debug-d81709316f/bin/openssl s_client -connect tls-13.example.com:44334 -CAfile tmp/test.crt -debug -trace
+ echo 'Passed from tls-13.example.com'
Passed from tls-13.example.com
```

No change for the listening processes.

```
$ ss -tnl | grep 4433[34]
LISTEN 0      4096               *:44333            *:*
LISTEN 0      4096               *:44334            *:*
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

The script works.

```
$ ./test.sh
+ ruby -I /home/jaruga/git/ruby/openssl/lib test.rb
Loaded from tls-12.example.com
Loaded from tls-13.example.com
```

No change for the listening processes.

```
$ ss -tnl | grep 4433[34]
LISTEN 0      4096               *:44333            *:*
LISTEN 0      4096               *:44334            *:*
```

### With Downstream OpenSSL RPM

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
...
+ grep '^TLS.Min' /etc/crypto-policies/back-ends/opensslcnf.config
TLS.MinProtocol = TLSv1.3
...
+ /bin/openssl s_client -connect tls-12.example.com:44333 -CAfile tmp/test.crt -debug -trace
+ echo 'Failed from tls-12.example.com'
Failed from tls-12.example.com
...
+ /bin/openssl s_client -connect tls-13.example.com:44334 -CAfile tmp/test.crt -debug -trace
+ echo 'Passed from tls-13.example.com'
Passed from tls-13.example.com
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
+ ruby -I /home/jaruga/git/ruby/openssl/lib test.rb
Failed to load from tls-12.example.com: SSL_connect returned=1 errno=0 peeraddr=127.0.0.1:44333 state=error: tlsv1 alert protocol version (SSL alert number 70)
Loaded from tls-13.example.com
```

If the Ruby OpenSSL doesn't include the above commit, it doesn't respect the OS system's minimal TLS protocol version, and overrides the setting as TLS version 1 (`OpenSSL::SSL::TLS1_VERSION`). As a result, the connection to the TLS 1.2 server passes as a following result.

```
$ ./test.sh
+ ruby -I /home/jaruga/git/ruby/openssl/lib test.rb
Loaded from tls-12.example.com
Loaded from tls-13.example.com
```
