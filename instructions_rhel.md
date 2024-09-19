# Instructions on RHEL

Create a test user.

```
# useradd tester
# echo "tester ALL = NOPASSWD: ALL" >> /etc/sudoers
```

Install Ruby RPM or Module.

```
# dnf -y install ruby
# dnf -y module install ruby:2.5
```

Install rubygem-test-unit RPM.

```
# dnf -y install rubygem-test-unit
```

Run the tests.

```
# su - tester
$ mkdir git
$ cd git
$ git clone https://github.com/junaruga/ruby-openssl-tls-min-version-test.git
$ cd ruby-openssl-tls-min-version-test
$ ./setup.sh
$ ./test_with_openssl_s_client.sh
```

Run the `test.sh` to run Ruby OpenSSL. The test script should fail for Ruby OpenSSL not applying the patch to fix the issue.

```
$ ./test.sh
```

Back up the patched file.

```
$ sudo cp /usr/share/ruby/openssl/ssl.rb{,.orig}
```

Apply the patch <https://github.com/ruby/openssl/pull/710> into the `/usr/share/ruby/openssl/ssl.rb`.

```
$ sudo vim /usr/share/ruby/openssl/ssl.rb
```

Confirm the above `test.sh` passes.

```
$ ./test.sh
```
