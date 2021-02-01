#!/bin/bash
set -e
rm -rf x86_64-linux-glibc2.11-4.6
tar xvf x86_64-linux-glibc2.11-4.6-orig.tar.bz2
pushd x86_64-linux-glibc2.11-4.6

echo "Add missing libxcb.so.*"
docker run --rm --entrypoint cat x86_64-linux-glibc2.11-4.6 /usr/lib/libxcb.so.1.1.0 > sysroot/usr/lib/libxcb.so.1.1.0
ln -sv libxcb.so.1.1.0 sysroot/usr/lib/libxcb.so.1
docker run --rm --entrypoint cat x86_64-linux-glibc2.11-4.6 /usr/lib32/libxcb.so.1.1.0 > sysroot/usr/lib32/libxcb.so.1.1.0
ln -sv libxcb.so.1.1.0 sysroot/usr/lib32/libxcb.so.1

echo "Update headers"
patch -p1 -i ../patches/Update-headers.patch

echo "Add missing X11 extension headers. (No action required)"

echo "stdatomic.h: Add new header file."
cp -v ../patches/stdatomic.h sysroot/usr/include/stdatomic.h

echo "Remove extra files"
rm -v lib/libiberty.a
rm -v sysroot/usr/lib{,32}/libXext.so
rm -v sysroot/usr/lib{,32}/libXext.a
rm -vr sysroot/usr/lib{,32}/xorg

popd

echo "Compare result with google prebuilt"
scripts/compare.sh

echo "Pack it into a final tarball"
tar -jcvf x86_64-linux-glibc2.11-4.6.tar.bz2 x86_64-linux-glibc2.11-4.6

echo "You can find the final artifact in x86_64-linux-glibc2.11-4.6.tar.bz2"
echo "The differences are found in build.diff"
echo "Have a nice day."
