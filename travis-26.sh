#!/usr/bin/env bash

set -x

# test $TRAVIS_PERL_VERSION" = 5.26 && perlbrew install perl-5.26.0 && perlbrew use perl-5.26.0
if [ "$TRAVIS_PERL_VERSION" = 5.26 ]; then
    if ! perlbrew use "$TRAVIS_PERL_VERSION"; then

        perlbrew install perl-5.26.0 || exit 1
        perlbrew use perl-5.26.0     || exit 1
    fi
fi

exit 0
