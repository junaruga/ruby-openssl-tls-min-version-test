#!/bin/bash

set -euxo pipefail

ruby -I ~/git/ruby/openssl/lib test.rb
# gdb --args ruby -I ~/git/ruby/openssl/lib test.rb
