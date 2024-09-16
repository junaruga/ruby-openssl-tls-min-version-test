# ruby-openssl-tls-min-version-test

This repository is to test Ruby OpenSSL for [this issue fix](https://github.com/ruby/openssl/pull/710).

## How to test

Customize the `OPENSSL_DIR` with your upstream OpenSSL install directory in the following files.

```
$ grep ^OPENSSL_DIR setup.sh test_with_openssl_s_client.sh
setup.sh:OPENSSL_DIR="${HOME}/.local/openssl-3.5.0-dev-fips-debug-d81709316f"
test_with_openssl_s_client.sh:OPENSSL_DIR="${HOME}/.local/openssl-3.5.0-dev-fips-debug-d81709316f"
```

### With openssl s_client program

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

The test result was below.

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

### With Ruby OpenSSL client program

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
