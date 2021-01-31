# This dockerfile is meant to be dynamic in that it downloads packages (other than via apt-get) via the internet
FROM ubuntu:10.04

# This Ubuntu doesn't have its packages on the normal server anymore
RUN sed -i -e "s/archive.ubuntu.com/old-releases.ubuntu.com/g" /etc/apt/sources.list

# Get some starter things
RUN apt-get update
RUN apt-get install tar wget gcc g++ make nano libc6-dev-i386 python-pip python-dev -y
RUN apt-get install python-argparse build-essential ia32-libs gcc-multilib g++-multilib -y
RUN apt-get install git-core python libcurl4-openssl-dev libz-dev gettext zlib1g-dev -y
RUN apt-get install checkinstall libgnutls-dev curl autoconf libtool -y
# Upgrade everything
RUN apt-get dist-upgrade -y

# Build not-so-new OpenSSL in order to build not-so-new curl with TLSv1.2 support
WORKDIR /usr/local
ARG bootstrapOpensslVer=1.0.1u
RUN wget https://www.openssl.org/source/openssl-${bootstrapOpensslVer}.tar.gz
RUN wget https://www.openssl.org/source/openssl-${bootstrapOpensslVer}.tar.gz.sha1 -O openssl.sha1
RUN sha1sum openssl-${bootstrapOpensslVer}.tar.gz > openssl.tar.gz.calc.sha1
# Verify SHA1
RUN python -c "assert open('openssl.sha1').read().strip() in open('openssl.tar.gz.calc.sha1').read().strip()"
# Remove SHA1 files
RUN rm openssl.sha1 openssl.tar.gz.calc.sha1
# Continue with OpenSSL
RUN tar -xvzf openssl-${bootstrapOpensslVer}.tar.gz
WORKDIR /usr/local/openssl-${bootstrapOpensslVer}
RUN ./config --prefix=/usr/local/openssl-bootstrap --openssldir=/usr/local/openssl-bootstrap shared zlib
RUN make -j4
RUN make install
RUN echo "/usr/local/openssl-bootstrap/lib" > /etc/ld.so.conf.d/openssl.conf
RUN ldconfig -v
RUN /usr/local/openssl-bootstrap/bin/openssl version
RUN rm -rf /usr/local/openssl-${bootstrapOpensslVer}.tar.gz /usr/local/openssl-${bootstrapOpensslVer}

# Build not-so-new curl in order to talk TLSv1.2
WORKDIR /usr/local
ARG bootstrapCurlVer=7.46.0
# FIXME: Find a more trustable mirror
RUN wget ftp://ftp.sunet.se/mirror/archive/ftp.sunet.se/pub/www/utilities/curl/curl-${bootstrapCurlVer}.tar.gz
RUN tar -zxvf curl-${bootstrapCurlVer}.tar.gz
WORKDIR /usr/local/curl-${bootstrapCurlVer}
RUN LIBS="-ldl" ./configure --with-ssl=/usr/local/openssl-bootstrap --enable-shared
RUN make -j4
RUN make install
RUN curl --version
RUN rm -rf /usr/local/curl-${bootstrapCurlVer}.tar.gz curl-${bootstrapCurlVer}

# Build new OpenSSL (needed for newer git and https to work)
WORKDIR /usr/local
ARG opensslVer=1.1.1i
RUN wget https://www.openssl.org/source/openssl-${opensslVer}.tar.gz
RUN wget https://www.openssl.org/source/openssl-${opensslVer}.tar.gz.sha1 -O openssl.sha1
RUN sha1sum openssl-${opensslVer}.tar.gz > openssl.tar.gz.calc.sha1
# Verify SHA1
RUN python -c "assert open('openssl.sha1').read().strip() in open('openssl.tar.gz.calc.sha1').read().strip()"
# Remove SHA1 files
RUN rm openssl.sha1 openssl.tar.gz.calc.sha1
# Continue with OpenSSL
RUN tar -xvzf openssl-${opensslVer}.tar.gz
WORKDIR /usr/local/openssl-${opensslVer}
RUN ./config --prefix=/usr/local/openssl --openssldir=/usr/local/openssl shared zlib
RUN make -j4
RUN make install
RUN rm -rf /usr/local/openssl-${opensslVer}.tar.gz /usr/local/openssl-${opensslVer}

# Build new curl with new OpenSSL for Git
WORKDIR /usr/local
ARG curlVer=7.74.0
RUN curl -o curl-${curlVer}.tar.gz https://curl.se/download/curl-${curlVer}.tar.gz
# Pause to adjust OpenSSL
RUN echo "/usr/local/openssl/lib" > /etc/ld.so.conf.d/openssl.conf
RUN ldconfig -v
RUN /usr/local/openssl/bin/openssl version
RUN rm -rf /usr/local/openssl-bootstrap
RUN tar -zxvf curl-${curlVer}.tar.gz
WORKDIR /usr/local/curl-${curlVer}
RUN LIBS="-ldl" ./configure --with-ssl=/usr/local/openssl --enable-shared
RUN make -j4
RUN make install
RUN curl --version
RUN rm -rf /usr/local/curl-${curlVer}.tar.gz curl-${curlVer}

# Download the latest .pem file for https connections via curl
RUN curl https://curl.haxx.se/ca/cacert.pem -o /cacert.pem

# Build new Git
WORKDIR /usr/local
ARG gitVer=2.30.0
RUN curl --cacert /cacert.pem -o git-${gitVer}.tar.gz https://mirrors.edge.kernel.org/pub/software/scm/git/git-${gitVer}.tar.gz
RUN tar -xvzf git-${gitVer}.tar.gz
WORKDIR /usr/local/git-${gitVer}
RUN ./configure --with-openssl=/usr/local/openssl
RUN make -j4
RUN make install
RUN git --version
RUN rm -rf /usr/local/git-${gitVer}.tar.gz /usr/local/git-${gitVer}

# Tell git to use the new certs
RUN echo "[http]" >> ~/.gitconfig
RUN echo "sslCAinfo = /cacert.pem" >> ~/.gitconfig

# Spawn shell
WORKDIR /
CMD "/bin/bash"
