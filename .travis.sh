#! /bin/bash

set -e -x

make -C control check

# the "yast-travis-ruby" script is included in the used Docker image,
# see https://github.com/yast/ci-ruby-container/blob/master/package/yast-travis-ruby
yast-travis-ruby

