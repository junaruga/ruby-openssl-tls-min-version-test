# ruby-openssl-tls-min-version-test

This repository is to test Ruby OpenSSL for [this issue fix](https://github.com/ruby/openssl/pull/710).

## How to test

Customize the `OPENSSL_DIR` with your upstream OpenSSL install directory in the following files.

```
$ grep ^OPENSSL_DIR setup.sh test_with_openssl_s_client.sh
setup.sh:OPENSSL_DIR="${HOME}/.local/openssl-3.4.0-dev-fips-debug-d550d2aae5"
test_with_openssl_s_client.sh:OPENSSL_DIR="${HOME}/.local/openssl-3.4.0-dev-fips-debug-d550d2aae5"
```

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

It seems that upstream OpenSSL doesn't refer to the OS's minimal TLS version.

I used the following upstream OpenSSL.

```
$ ~/.local/openssl-3.4.0-dev-fips-debug-d550d2aae5/bin/openssl version
OpenSSL 3.4.0-dev  (Library: OpenSSL 3.4.0-dev )
```

According to [this article](https://stackoverflow.com/questions/27430158/list-supported-ssl-tls-versions-for-a-specific-openssl-build), below is the command to check the supported TLS versions.

```
$ ~/.local/openssl-3.4.0-dev-fips-debug-d550d2aae5/bin/openssl ciphers -v | awk '{print $2}' | sort | uniq
SSLv3
TLSv1
TLSv1.2
TLSv1.3
```

Compile Ruby OpenSSL with the upstream OpenSSL.

```
$ OPENSSL_DIR="${HOME}/.local/openssl-3.4.0-dev-fips-debug-d550d2aae5"

$ MAKEFLAGS="V=1" \
  RUBY_OPENSSL_EXTCFLAGS="-O0 -g3 -ggdb3 -gdwarf-5" \
  bundle exec rake compile -- \
  --with-openssl-dir="${OPENSSL_DIR}"
```

The test result was below. So, it seems the upstream OpenSSL have own internal minimal TLS version in it.

```
$ ./test_with_openssl_s_client.sh
...
Failed from tls-12.example.com
...
Passed from tls-13.example.com
```

Run the setup script again to run the SSL TLS servers.

```
$ ./setup.sh
```

SSL TLS servers are running on the following ports.

```
$ ss -tnl | grep 4433[34]
LISTEN 0      4096               *:44333            *:*
LISTEN 0      4096               *:44334            *:*
```

The following error happened.

```
$ ./test.sh
+ ruby -I /home/jaruga/git/ruby/openssl/lib test.rb
Failed to load from tls-12.example.com: SSL_connect returned=1 errno=107 peeraddr=(null) state=error: unexpected eof while reading
^C/home/jaruga/.local/ruby-3.4.0dev-debug-82aee1a946/lib/ruby/3.4.0+0/net/protocol.rb:229:in 'IO#wait_readable': Interrupt
	from /home/jaruga/.local/ruby-3.4.0dev-debug-82aee1a946/lib/ruby/3.4.0+0/net/protocol.rb:229:in 'Net::BufferedIO#rbuf_fill'
	from /home/jaruga/.local/ruby-3.4.0dev-debug-82aee1a946/lib/ruby/3.4.0+0/net/protocol.rb:199:in 'Net::BufferedIO#readuntil'
	from /home/jaruga/.local/ruby-3.4.0dev-debug-82aee1a946/lib/ruby/3.4.0+0/net/protocol.rb:209:in 'Net::BufferedIO#readline'
	from /home/jaruga/.local/ruby-3.4.0dev-debug-82aee1a946/lib/ruby/3.4.0+0/net/http/response.rb:158:in 'Net::HTTPResponse.read_status_line'
	from /home/jaruga/.local/ruby-3.4.0dev-debug-82aee1a946/lib/ruby/3.4.0+0/net/http/response.rb:147:in 'Net::HTTPResponse.read_new'
	from /home/jaruga/.local/ruby-3.4.0dev-debug-82aee1a946/lib/ruby/3.4.0+0/net/http.rb:2420:in 'block in Net::HTTP#transport_request'
	from /home/jaruga/.local/ruby-3.4.0dev-debug-82aee1a946/lib/ruby/3.4.0+0/net/http.rb:2411:in 'Kernel#catch'
	from /home/jaruga/.local/ruby-3.4.0dev-debug-82aee1a946/lib/ruby/3.4.0+0/net/http.rb:2411:in 'Net::HTTP#transport_request'
	from /home/jaruga/.local/ruby-3.4.0dev-debug-82aee1a946/lib/ruby/3.4.0+0/net/http.rb:2384:in 'Net::HTTP#request'
	from /home/jaruga/.local/ruby-3.4.0dev-debug-82aee1a946/lib/ruby/3.4.0+0/net/http.rb:1990:in 'Net::HTTP#get'
	from test.rb:21:in 'block (2 levels) in <main>'
	from /home/jaruga/.local/ruby-3.4.0dev-debug-82aee1a946/lib/ruby/3.4.0+0/net/http.rb:1632:in 'Net::HTTP#start'
	from /home/jaruga/.local/ruby-3.4.0dev-debug-82aee1a946/lib/ruby/3.4.0+0/net/http.rb:1070:in 'Net::HTTP.start'
	from test.rb:17:in 'block in <main>'
	from <internal:array>:53:in 'Array#each'
	from test.rb:11:in '<main>'
```
