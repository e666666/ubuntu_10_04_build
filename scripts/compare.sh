#!/bin/bash
git clone https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/host/x86_64-linux-glibc2.11-4.6 -b studio-1.3-release google
diff --exclude .git -ruN google/ x86_64-linux-glibc2.11-4.6/ | tee build.diff
