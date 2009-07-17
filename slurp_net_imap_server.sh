#!/bin/bash

(cd ../net-imap-server; git checkout working; git reset --hard; git clean -dfx; perl Makefile.PL; make)

echo
echo
echo "making dirs if necessary"

find ../net-imap-server/blib/lib/Net -type d | sed s,.*blib/lib/,inc/, | xargs mkdir -vp
for src in `find ../net-imap-server/blib/lib/Net -type f -name \*.pm`; do
    srcdir=`dirname $src`;
    file=`basename $src`;
    dstdir=`echo $srcdir | sed s,.*blib/lib/,inc/,`

    cp -fuva $srcdir/$file $dstdir/$file
done
