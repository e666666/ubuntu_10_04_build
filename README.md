Original Dockerfile credit: https://github.com/csm10495/ubuntu_10_04_build

My attempt to automate building of "platform/prebuilts/gcc/linux-x86/host/x86_64-linux-glibc2.11-4.6" from the AOSP.

To replicate, run in the repo:
docker build -t x86_64-linux-glibc2.11-4.6.git --ulimit nofile=1024 .
