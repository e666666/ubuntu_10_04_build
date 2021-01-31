#!/bin/bash
set -e
rm -rf x86_64-linux-glibc2.11-4.6
tar xvf x86_64-linux-glibc2.11-4.6-orig.tar.bz2
pushd x86_64-linux-glibc2.11-4.6

# Add missing libxcb.so.*
docker run --rm --entrypoint cat x86_64-linux-glibc2.11-4.6 /usr/lib/libxcb.so.1.1.0 > sysroot/usr/lib/libxcb.so.1.1.0
ln -sv libxcb.so.1.1.0 sysroot/usr/lib/libxcb.so.1
docker run --rm --entrypoint cat x86_64-linux-glibc2.11-4.6 /usr/lib32/libxcb.so.1.1.0 > sysroot/usr/lib32/libxcb.so.1.1.0
ln -sv libxcb.so.1.1.0 sysroot/usr/lib32/libxcb.so.1

# Update headers
