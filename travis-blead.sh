#!/usr/bin/env bash

set -x

if [ "$TRAVIS_PERL_VERSION" = perl-blead ]; then
    if ! perlbrew use "$TRAVIS_PERL_VERSION"; then

        perlbrew install perl-blead || exit 1
        perlbrew use perl-blead     || exit 1
    fi
fi

exit 0
