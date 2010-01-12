#!/bin/sh

srcdir=`dirname $0`
test -z "$srcdir" && srcdir=.

ORIGDIR=`pwd`
cd $srcdir

intltoolize --force
autoreconf -v --install || exit 1
cd $ORIGDIR || exit $?

$srcdir/configure "$@"
