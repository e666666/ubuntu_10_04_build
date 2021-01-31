#!/bin/bash
set -e
docker build -t x86_64-linux-glibc2.11-4.6 --ulimit nofile=1024 . && docker run --rm --entrypoint cat x86_64-linux-glibc2.11-4.6 /tmp/x86_64-linux-glibc2.11-4.6.tar.bz2 > x86_64-linux-glibc2.11-4.6-orig.tar.bz2
scripts/postprocessing.sh
