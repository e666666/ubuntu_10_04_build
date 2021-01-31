Original Dockerfile credit: https://github.com/csm10495/ubuntu_10_04_build

My attempt to automate building of "platform/prebuilts/gcc/linux-x86/host/x86_64-linux-glibc2.11-4.6" from the AOSP.

To replicate, run in the repo (Remove --no-cache to speed up sequent builds):
docker build -t x86_64-linux-glibc2.11-4.6.git --ulimit nofile=1024 --no-cache .
