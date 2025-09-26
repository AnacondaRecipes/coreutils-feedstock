#!/usr/bin/env bash
set -euxo pipefail

cp -r ${BUILD_PREFIX}/share/libtool/build-aux/config.* ./build-aux

export FORCE_UNSAFE_CONFIGURE=1

./configure \
  --prefix="$PREFIX" \
  --disable-rpath \
  --enable-silent-rules \
  --disable-nls

make -j "${CPU_COUNT}"
make install
make installcheck
