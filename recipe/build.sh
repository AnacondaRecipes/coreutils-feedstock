#!/usr/bin/env bash

cp -r ${BUILD_PREFIX}/share/libtool/build-aux/config.* ./build-aux

FORCE_UNSAFE_CONFIGURE=1 ./configure --prefix=$PREFIX

make -j $CPU_COUNT
make install
make installcheck
