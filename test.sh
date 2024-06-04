#!/bin/bash

set -euxo pipefail

ruby -I ~/git/ruby/openssl/lib tmp/test.rb
