FROM aneundorf/centos5-build-base
LABEL maintainer="alexander.neundorf@sharpreflections.com,dennis.brendel@sharpreflections.com"

# This container extends the build-base container by compiling a few
# versions of svn and git

# Build a recent enough openssl, since the system openssl only supports deprecated
# ciphers which are removed from recent systems (svn can no longer checkout)

WORKDIR /tmp/src
RUN curl -LO https://www.openssl.org/source/old/1.0.2/openssl-1.0.2u.tar.gz && \
    tar xvf openssl-1.0.2u.tar.gz && \
    cd openssl-1.0.2u && \
    ./config shared --prefix=/opt/openssl-1.0.2u && \
    make -j 4 && \
    make -j 4 install && \
    cd /tmp/src && \
    rm -rf /tmp/src/*


# build svn 1.7.22
# get a recent enough sqlite:
WORKDIR /tmp/src
RUN svn co http://svn.apache.org/repos/asf/apr/apr/branches/1.3.x apr-1.3 && \
    cd apr-1.3 && \
    ./buildconf && \
    ./configure --prefix=/opt/apr-1.3 --enable-shared --disable-static && \
    make -j4 && \
    make install && \
    cd /tmp/src && \
    svn co  http://svn.apache.org/repos/asf/apr/apr-util/branches/1.3.x  apr-util-1.3  && \
    cd apr-util-1.3 && \
    ./buildconf --with-apr=../apr-1.3 && \
    ./configure --prefix=/opt/apr-1.3 --with-apr=../apr-1.3/ --enable-shared --disable-static && \
    make -j4 && \
    make install && \
# install scons, needed to build Serf
#    wget -P /tmp/dl http://prdownloads.sourceforge.net/scons/scons-local-2.3.0.tar.gz && \
cd /opt && \
    mkdir -p /tmp/dl && \
    mkdir -p /opt/scons-2.3 && \
    wget -P /tmp/dl http://netcologne.dl.sourceforge.net/project/scons/scons-local/2.3.0/scons-local-2.3.0.tar.gz && \
    cd scons-2.3 && \
    tar -zxvf /tmp/dl/scons-local-2.3.0.tar.gz && \
    rm /tmp/dl/* && rm -rf /tmp/src/*


# get Apache Serf (needed for https in svn)
WORKDIR /tmp/src
RUN wget http://www.apache.org/dist/serf/serf-1.3.9.tar.bz2 && \
    tar -jxvf serf-1.3.9.tar.bz2 && \
    cd serf-1.3.9 && \
    /opt/scons-2.3/scons.py PREFIX=/opt/serf-1.3.9 APR=/opt/apr-1.3 APU=/opt/apr-1.3 OPENSSL=/opt/openssl-1.0.2u && \
    /opt/scons-2.3/scons.py install && \
    cd /tmp/src && \
    rm -rf /tmp/src/*


# build svn 1.7
WORKDIR /tmp/src
RUN wget http://archive.apache.org/dist/subversion/subversion-1.7.22.tar.gz &&  \
    tar -zxvf subversion-1.7.22.tar.gz && \
    mkdir /tmp/src/subversion-1.7.22/sqlite-amalgamation && \
    wget http://www.sqlite.org/2016/sqlite-autoconf-3150100.tar.gz && \
    tar -zxvf sqlite-autoconf-3150100.tar.gz && \
    cp sqlite-autoconf-3150100/sqlite3.c /tmp/src/subversion-1.7.22/sqlite-amalgamation/    && \
    cd subversion-1.7.22 && \
    ./configure --prefix=/opt/svn-1.7 --without-berkeley-db --without-apxs --without-swig --with-apr=/opt/apr-1.3/ --with-apr-util=/opt/apr-1.3/ --with-serf=/opt/serf-1.3.9/ && \
    nice make -j6 && \
    make install && \
    cd /tmp/src && \
    rm -rf /tmp/src/*


# build svn 1.8
WORKDIR /tmp/src
RUN wget http://archive.apache.org/dist/subversion/subversion-1.8.16.tar.gz && \
    tar -zxvf subversion-1.8.16.tar.gz && \
    wget http://www.sqlite.org/2016/sqlite-autoconf-3150100.tar.gz && \
    tar -zxvf sqlite-autoconf-3150100.tar.gz && \
    cp -R sqlite-autoconf-3150100 subversion-1.8.16/sqlite-amalgamation && \
    cd subversion-1.8.16 && \
    ./configure --prefix=/opt/svn-1.8 --without-berkeley-db --without-apxs --without-swig --with-apr=/opt/apr-1.3/ --with-apr-util=/opt/apr-1.3/ --with-serf=/opt/serf-1.3.9/ && \
    nice make -j4 && \
    make install && \
    mv /opt/svn-1.8/bin/svn /opt/svn-1.8/bin/svn18 && \
    echo $'#!/bin/bash \n LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/opt/serf-1.3.9/lib/ /opt/svn-1.8/bin/svn18 $*' > /opt/svn-1.8/bin/svn  && \
    chmod 755 /opt/svn-1.8/bin/svn && \
    cd /tmp/src && \
    rm -rf /tmp/src/*


# build git
WORKDIR /tmp/src
# wget from www.kernel.org failed with an ssl error. source packages in newer distros are usually xz, which we can't unpack on centos5
RUN wget http://ftp5.gwdg.de/pub/linux/slackware/slackware-12.2/source/d/git/git-1.6.0.3.tar.bz2 && \
    tar -jxvf git-1.6.0.3.tar.bz2 && \
    cd git-1.6.0.3 && \
    ./configure --prefix=/opt/git  && \
    make -j4 && \
    make install && \
    cd /tmp/src && \
    rm -rf /tmp/src/*

