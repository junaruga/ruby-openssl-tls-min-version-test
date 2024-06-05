# ruby-openssl-tls-min-version-test

Set up tesing SSL environment with HTTPD.

```
$ ./setup.sh
```

Run a testing Ruby script.

```
$ ./test.sh
+ ruby -I /home/jaruga/git/ruby/openssl/lib tmp/test.rb
Failed to load from tls-10.example.com: SSL_connect returned=1 errno=0 peeraddr=127.0.0.1:443 state=error: tlsv1 alert protocol version (SSL alert number 70)
Failed to load from tls-11.example.com: SSL_connect returned=1 errno=0 peeraddr=127.0.0.1:443 state=error: tlsv1 alert protocol version (SSL alert number 70)
Loaded from tls-12.example.com
Loaded from tls-13.example.com
```
