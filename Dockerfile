# This dockerfile is meant to be dynamic in that it downloads packages (other than via apt-get) via the internet
FROM ubuntu:10.04

# This Ubuntu doesn't have its packages on the normal server anymore
RUN sed -i -e "s/archive.ubuntu.com/old-releases.ubuntu.com/g" /etc/apt/sources.list

# Install deps and upgrade everything
RUN apt-get update
RUN apt-get dist-upgrade -y
RUN apt-get install tar wget gcc g++ make nano libc6-dev-i386 python-pip python-dev python-argparse build-essential ia32-libs gcc-multilib g++-multilib git-core python libcurl4-openssl-dev libz-dev gettext zlib1g-dev checkinstall libgnutls-dev curl autoconf libtool bison flex patch texinfo -y


# Build not-so-new OpenSSL in order to build not-so-new curl with TLSv1.2 support
WORKDIR /usr/local
ARG bootstrapOpensslVer=1.0.1u
RUN wget https://www.openssl.org/source/openssl-${bootstrapOpensslVer}.tar.gz
RUN tar -xvzf openssl-${bootstrapOpensslVer}.tar.gz
WORKDIR /usr/local/openssl-${bootstrapOpensslVer}
RUN ./config --prefix=/usr/local/openssl-bootstrap --openssldir=/usr/local/openssl-bootstrap shared zlib
RUN make -j6
RUN make install
RUN echo "/usr/local/openssl-bootstrap/lib" > /etc/ld.so.conf.d/openssl.conf
RUN ldconfig -v
RUN /usr/local/openssl-bootstrap/bin/openssl version

# Build not-so-new curl in order to talk TLSv1.2
WORKDIR /usr/local
ARG bootstrapCurlVer=7.46.0
# FIXME: Find a more trustable mirror
RUN wget ftp://ftp.sunet.se/mirror/archive/ftp.sunet.se/pub/www/utilities/curl/curl-${bootstrapCurlVer}.tar.gz
RUN tar -zxvf curl-${bootstrapCurlVer}.tar.gz
WORKDIR /usr/local/curl-${bootstrapCurlVer}
RUN LIBS="-ldl" ./configure --prefix=/usr --with-ssl=/usr/local/openssl-bootstrap --enable-shared
RUN make -j6
RUN make install
RUN curl --version

# Build new OpenSSL (needed for newer git and https to work)
WORKDIR /usr/local
ARG opensslVer=1.1.1i
RUN wget https://www.openssl.org/source/openssl-${opensslVer}.tar.gz
RUN tar -xvzf openssl-${opensslVer}.tar.gz
WORKDIR /usr/local/openssl-${opensslVer}
RUN ./config --prefix=/usr/local/openssl --openssldir=/usr/local/openssl shared zlib
RUN make -j6
RUN make install

# Build new curl with new OpenSSL for Git
WORKDIR /usr/local
ARG curlVer=7.74.0
RUN curl -o curl-${curlVer}.tar.gz https://curl.se/download/curl-${curlVer}.tar.gz

# Pause to adjust OpenSSL
RUN echo "/usr/local/openssl/lib" > /etc/ld.so.conf.d/openssl.conf
RUN ldconfig -v
RUN /usr/local/openssl/bin/openssl version
RUN rm -rf /usr/local/openssl-bootstrap

# Continue with the build
RUN tar -zxvf curl-${curlVer}.tar.gz
WORKDIR /usr/local/curl-${curlVer}
RUN LIBS="-ldl" ./configure --prefix=/usr --with-ssl=/usr/local/openssl --enable-shared
RUN make -j6
RUN make install
RUN curl --version

# Download the latest .pem file for https connections via curl
RUN curl https://curl.haxx.se/ca/cacert.pem -o /cacert.pem


# Build new Git
WORKDIR /usr/local
ARG gitVer=2.30.0
RUN curl --cacert /cacert.pem -o git-${gitVer}.tar.gz https://mirrors.edge.kernel.org/pub/software/scm/git/git-${gitVer}.tar.gz
RUN tar -xvzf git-${gitVer}.tar.gz
WORKDIR /usr/local/git-${gitVer}
RUN ./configure --with-openssl=/usr/local/openssl
RUN make -j6
RUN make install
RUN git --version

# Tell git to use the new certs
RUN echo "[http]" >> ~/.gitconfig
RUN echo "sslCAinfo = /cacert.pem" >> ~/.gitconfig


# Prepare the source tree
WORKDIR /
RUN git clone https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/host/x86_64-linux-glibc2.11-4.6 -b studio-1.3-release
RUN mkdir wd/
RUN (cd x86_64-linux-glibc2.11-4.6 && cp -a build-lucid-multilib-toolchain.sh toolchain-patches ../wd/)

# Download and build GCC
WORKDIR /wd
# Patches to make stuff work and also ease debugging
COPY buildScript-specifyBuildTask.patch /buildScript-specifyBuildTask.patch
RUN patch -i ../buildScript-specifyBuildTask.patch
COPY buildScript-fixVerboseBuild.patch /buildScript-fixVerboseBuild.patch
RUN patch -i ../buildScript-fixVerboseBuild.patch

# Build dat thing
RUN ./build-lucid-multilib-toolchain.sh --bootstrap --git-date=2014-03-05T13:04:07+0000 --work-dir=/wd --ubuntu-mirror=http://old-releases.ubuntu.com/ --verbose
