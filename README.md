# ruby-openssl-tls-min-version-test

This repository is to test Ruby OpenSSL for [this issue fix](https://github.com/ruby/openssl/pull/710).

## How to test

Customize the `OPENSSL_DIR` with your upstream OpenSSL install directory in the following files.

```
$ grep ^OPENSSL_DIR setup.sh test_with_openssl_s_client.sh
setup.sh:OPENSSL_DIR="${HOME}/.local/openssl-3.4.0-dev-fips-debug-d550d2aae5"
test_with_openssl_s_client.sh:OPENSSL_DIR="${HOME}/.local/openssl-3.4.0-dev-fips-debug-d550d2aae5"
```

### With openssl s_client program

Set up tesing environment running SSL TLS servers with `openssl s_server`.

```
$ ./setup.sh
...
+ /home/jaruga/.local/openssl-3.4.0-dev-fips-debug-d550d2aae5/bin/openssl version
OpenSSL 3.4.0-dev  (Library: OpenSSL 3.4.0-dev )
+ /home/jaruga/.local/openssl-3.4.0-dev-fips-debug-d550d2aae5/bin/openssl genrsa -out ./tmp/test.key 4096
+ /home/jaruga/.local/openssl-3.4.0-dev-fips-debug-d550d2aae5/bin/openssl req -new -key ./tmp/test.key -config cert.conf -out ./tmp/test.csr -sha512 -batch
+ /home/jaruga/.local/openssl-3.4.0-dev-fips-debug-d550d2aae5/bin/openssl x509 -req -in ./tmp/test.csr -signkey ./tmp/test.key -out ./tmp/test.crt -sha512
...
+ /home/jaruga/.local/openssl-3.4.0-dev-fips-debug-d550d2aae5/bin/openssl s_server -port 44333 -servername tls-12.example.com -tls1_2 -cert ./tmp/test.crt -key ./tmp/test.key -cert2 ./tmp/test.crt -key2 ./tmp/test.key -debug -trace
...
+ /home/jaruga/.local/openssl-3.4.0-dev-fips-debug-d550d2aae5/bin/openssl s_server -port 44334 -servername tls-13.example.com -tls1_3 -cert ./tmp/test.crt -key ./tmp/test.key -cert2 ./tmp/test.crt -key2 ./tmp/test.key -debug -trace
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
$ ~/.local/openssl-3.4.0-dev-fips-debug-d550d2aae5/bin/openssl ciphers -v | awk '{print $2}' | sort | uniq
SSLv3
TLSv1
TLSv1.2
TLSv1.3
```

The test result was below. So, it seems the upstream OpenSSL have own internal minimal TLS version in it.

```
$ ./test_with_openssl_s_client.sh
...
+ /home/jaruga/.local/openssl-3.4.0-dev-fips-debug-d550d2aae5/bin/openssl s_client -connect tls-12.example.com:44333 -CAfile tmp/test.crt -debug -trace
+ echo 'Failed from tls-12.example.com'
Failed from tls-12.example.com
...
+ /home/jaruga/.local/openssl-3.4.0-dev-fips-debug-d550d2aae5/bin/openssl s_client -connect tls-13.example.com:44334 -CAfile tmp/test.crt -debug -trace
+ echo 'Passed from tls-13.example.com'
Passed from tls-13.example.com
```

The TLS 1.2 server's listening process is down.

```
$ ss -tnl | grep 4433[34]
LISTEN 0      4096               *:44334            *:*
```

Below is the stderr log by the `openssl s_client`.

```
$ cat log/openssl-s_client/tls-12.example.com.stderr.log
Connecting to 127.0.0.1
809B99AC407F0000:error:0A000126:SSL routines::unexpected eof while reading:ssl/record/rec_layer_s3.c:688:
```

Below is the stdout log by the `openssl s_client`.

```
$ cat log/openssl-s_client/tls-12.example.com.stdout.log
CONNECTED(00000003)
Sent TLS Record
Header:
  Version = TLS 1.0 (0x301)
  Content Type = Handshake (22)
  Length = 324
    ClientHello, Length=320
      client_version=0x303 (TLS 1.2)
      Random:
        gmt_unix_time=0x26BAC938
        random_bytes (len=28): F9CB414FA28015B495C519389AD5D018B26B7BF58F29F00B9D06C82C
      session_id (len=32): BA15179614CD01D8F3988F5E820F83E69DAD398336FD53FA77339388AD1253F6
      cipher_suites (len=60)
        {0x13, 0x02} TLS_AES_256_GCM_SHA384
        {0x13, 0x03} TLS_CHACHA20_POLY1305_SHA256
        {0x13, 0x01} TLS_AES_128_GCM_SHA256
        {0xC0, 0x2C} TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384
        {0xC0, 0x30} TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384
        {0x00, 0x9F} TLS_DHE_RSA_WITH_AES_256_GCM_SHA384
        {0xCC, 0xA9} TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305_SHA256
        {0xCC, 0xA8} TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305_SHA256
        {0xCC, 0xAA} TLS_DHE_RSA_WITH_CHACHA20_POLY1305_SHA256
        {0xC0, 0x2B} TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256
        {0xC0, 0x2F} TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256
        {0x00, 0x9E} TLS_DHE_RSA_WITH_AES_128_GCM_SHA256
        {0xC0, 0x24} TLS_ECDHE_ECDSA_WITH_AES_256_CBC_SHA384
        {0xC0, 0x28} TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA384
        {0x00, 0x6B} TLS_DHE_RSA_WITH_AES_256_CBC_SHA256
        {0xC0, 0x23} TLS_ECDHE_ECDSA_WITH_AES_128_CBC_SHA256
        {0xC0, 0x27} TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA256
        {0x00, 0x67} TLS_DHE_RSA_WITH_AES_128_CBC_SHA256
        {0xC0, 0x0A} TLS_ECDHE_ECDSA_WITH_AES_256_CBC_SHA
        {0xC0, 0x14} TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA
        {0x00, 0x39} TLS_DHE_RSA_WITH_AES_256_CBC_SHA
        {0xC0, 0x09} TLS_ECDHE_ECDSA_WITH_AES_128_CBC_SHA
        {0xC0, 0x13} TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA
        {0x00, 0x33} TLS_DHE_RSA_WITH_AES_128_CBC_SHA
        {0x00, 0x9D} TLS_RSA_WITH_AES_256_GCM_SHA384
        {0x00, 0x9C} TLS_RSA_WITH_AES_128_GCM_SHA256
        {0x00, 0x3D} TLS_RSA_WITH_AES_256_CBC_SHA256
        {0x00, 0x3C} TLS_RSA_WITH_AES_128_CBC_SHA256
        {0x00, 0x35} TLS_RSA_WITH_AES_256_CBC_SHA
        {0x00, 0x2F} TLS_RSA_WITH_AES_128_CBC_SHA
      compression_methods (len=1)
        No Compression (0x00)
      extensions, length = 187
        extension_type=renegotiate(65281), length=1
            <EMPTY>
        extension_type=server_name(0), length=23
          0000 - 00 15 00 00 12 74 6c 73-2d 31 32 2e 65 78 61   .....tls-12.exa
          000f - 6d 70 6c 65 2e 63 6f 6d-                       mple.com
        extension_type=ec_point_formats(11), length=4
          uncompressed (0)
          ansiX962_compressed_prime (1)
          ansiX962_compressed_char2 (2)
        extension_type=supported_groups(10), length=22
          ecdh_x25519 (29)
          secp256r1 (P-256) (23)
          ecdh_x448 (30)
          secp521r1 (P-521) (25)
          secp384r1 (P-384) (24)
          ffdhe2048 (256)
          ffdhe3072 (257)
          ffdhe4096 (258)
          ffdhe6144 (259)
          ffdhe8192 (260)
        extension_type=session_ticket(35), length=0
        extension_type=encrypt_then_mac(22), length=0
        extension_type=extended_master_secret(23), length=0
        extension_type=signature_algorithms(13), length=48
          ecdsa_secp256r1_sha256 (0x0403)
          ecdsa_secp384r1_sha384 (0x0503)
          ecdsa_secp521r1_sha512 (0x0603)
          ed25519 (0x0807)
          ed448 (0x0808)
          ecdsa_brainpoolP256r1_sha256 (0x081a)
          ecdsa_brainpoolP384r1_sha384 (0x081b)
          ecdsa_brainpoolP512r1_sha512 (0x081c)
          rsa_pss_pss_sha256 (0x0809)
          rsa_pss_pss_sha384 (0x080a)
          rsa_pss_pss_sha512 (0x080b)
          rsa_pss_rsae_sha256 (0x0804)
          rsa_pss_rsae_sha384 (0x0805)
          rsa_pss_rsae_sha512 (0x0806)
          rsa_pkcs1_sha256 (0x0401)
          rsa_pkcs1_sha384 (0x0501)
          rsa_pkcs1_sha512 (0x0601)
          ecdsa_sha224 (0x0303)
          rsa_pkcs1_sha224 (0x0301)
          dsa_sha224 (0x0302)
          dsa_sha256 (0x0402)
          dsa_sha384 (0x0502)
          dsa_sha512 (0x0602)
        extension_type=supported_versions(43), length=5
          TLS 1.3 (772)
          TLS 1.2 (771)
        extension_type=psk_key_exchange_modes(45), length=2
          psk_dhe_ke (1)
        extension_type=key_share(51), length=38
            NamedGroup: ecdh_x25519 (29)
            key_exchange:  (len=32): 06D1BF9878F0F3A77FD6B6C7CA803B6340CAFA4DC1F84779A263F31F191E4533

write to 0x2fd43bc0 [0x2fd4ff70] (329 bytes => 329 (0x149))
0000 - 16 03 01 01 44 01 00 01-40 03 03 26 ba c9 38 f9   ....D...@..&..8.
0010 - cb 41 4f a2 80 15 b4 95-c5 19 38 9a d5 d0 18 b2   .AO.......8.....
0020 - 6b 7b f5 8f 29 f0 0b 9d-06 c8 2c 20 ba 15 17 96   k{..)....., ....
0030 - 14 cd 01 d8 f3 98 8f 5e-82 0f 83 e6 9d ad 39 83   .......^......9.
0040 - 36 fd 53 fa 77 33 93 88-ad 12 53 f6 00 3c 13 02   6.S.w3....S..<..
0050 - 13 03 13 01 c0 2c c0 30-00 9f cc a9 cc a8 cc aa   .....,.0........
0060 - c0 2b c0 2f 00 9e c0 24-c0 28 00 6b c0 23 c0 27   .+./...$.(.k.#.'
0070 - 00 67 c0 0a c0 14 00 39-c0 09 c0 13 00 33 00 9d   .g.....9.....3..
0080 - 00 9c 00 3d 00 3c 00 35-00 2f 01 00 00 bb ff 01   ...=.<.5./......
0090 - 00 01 00 00 00 00 17 00-15 00 00 12 74 6c 73 2d   ............tls-
00a0 - 31 32 2e 65 78 61 6d 70-6c 65 2e 63 6f 6d 00 0b   12.example.com..
00b0 - 00 04 03 00 01 02 00 0a-00 16 00 14 00 1d 00 17   ................
00c0 - 00 1e 00 19 00 18 01 00-01 01 01 02 01 03 01 04   ................
00d0 - 00 23 00 00 00 16 00 00-00 17 00 00 00 0d 00 30   .#.............0
00e0 - 00 2e 04 03 05 03 06 03-08 07 08 08 08 1a 08 1b   ................
00f0 - 08 1c 08 09 08 0a 08 0b-08 04 08 05 08 06 04 01   ................
0100 - 05 01 06 01 03 03 03 01-03 02 04 02 05 02 06 02   ................
0110 - 00 2b 00 05 04 03 04 03-03 00 2d 00 02 01 01 00   .+........-.....
0120 - 33 00 26 00 24 00 1d 00-20 06 d1 bf 98 78 f0 f3   3.&.$... ....x..
0130 - a7 7f d6 b6 c7 ca 80 3b-63 40 ca fa 4d c1 f8 47   .......;c@..M..G
0140 - 79 a2 63 f3 1f 19 1e 45-33                        y.c....E3
read from 0x2fd43bc0 [0x2fd555a3] (5 bytes => 0)
Sent TLS Record
Header:
  Version = TLS 1.0 (0x301)
  Content Type = Alert (21)
  Length = 2
write to 0x2fd43bc0 [0x2fd4ff70] (7 bytes => -1)
    Level=fatal(2), description=decode error(50)

---
no peer certificate available
---
No client certificate CA names sent
---
SSL handshake has read 0 bytes and written 329 bytes
Verification: OK
---
New, (NONE), Cipher is (NONE)
This TLS version forbids renegotiation.
Compression: NONE
Expansion: NONE
No ALPN negotiated
Early data was not sent
Verify return code: 0 (ok)
---
read from 0x2fd43bc0 [0x2fcf1400] (16384 bytes => 0)
```

Below is the stderr log by the `openssl s_server`.

```
$ cat log/openssl-s_server/tls-12.example.com.stderr.log
shutdown accept socket
```

Below is the stdout log by the `openssl s_server`.

```
$ cat log/openssl-s_server/tls-12.example.com.stdout.log
Setting secondary ctx parameters
Using default temp DH parameters
ACCEPT
DONE
shutting down SSL
CONNECTION CLOSED
   0 items in the session cache
   0 client connects (SSL_connect())
   0 client renegotiates (SSL_connect())
   0 client connects that finished
   0 server accepts (SSL_accept())
   0 server renegotiates (SSL_accept())
   0 server accepts that finished
   0 session cache hits
   0 session cache misses
   0 session cache timeouts
   0 callback cache hits
   0 cache full overflows (128 allowed)
```

### With Ruby OpenSSL client program

Compile Ruby OpenSSL with the upstream OpenSSL.

```
$ cd /home/jaruga/git/ruby/openssl

$ OPENSSL_DIR="${HOME}/.local/openssl-3.4.0-dev-fips-debug-d550d2aae5"

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

The following error happened.

```
$ ./test.sh
+ ruby -I /home/jaruga/git/ruby/openssl/lib test.rb
Failed to load from tls-12.example.com: SSL_connect returned=1 errno=107 peeraddr=(null) state=error: unexpected eof while reading

Failed to load from tls-13.example.com: Failed to open TCP connection to tls-13.example.com:44334 (Connection refused - connect(2) for "tls-13.example.com" port 44334)
```

The both TLS 1.2 and 1.3 servers' listening processes are down.

```
$ ss -tnl | grep 4433[34]
```
