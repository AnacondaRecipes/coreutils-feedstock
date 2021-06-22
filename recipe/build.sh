#!/usr/bin/env bash

FORCE_UNSAFE_CONFIGURE=1 ./configure --prefix=$PREFIX

# Try and see
export LDFLAGS="${LDFLAGS} -Wl,--allow-multiple-definition"
export CFLAGS="${CFLAGS} -DSYS_getdents=SYS_getdents64"  # getdens is defined to getdesnts64

echo "----------- Variables -------------"
echo "FORCE_UNSAFE_CONFIGURE: "${FORCE_UNSAFE_CONFIGURE}
echo "PREFIX: "${PREFIX}
echo "CFLAGS: "${CFLAGS}
echo "LDFLAGS: "${LDFLAGS}
echo "CMAKE_CXX_FLAGS: "${CMAKE_CXX_FLAGS}
echo "CPU_COUNT: "${CPU_COUNT}
echo "HOST: "${HOST}
echo "BUILD: "${BUILD}
echo "target_platform: "${target_platform}
echo "_CONDA_PYTHON_SYSCONFIGDATA_NAME: "${_CONDA_PYTHON_SYSCONFIGDATA_NAME}
echo "-----------------------------------"

make -j $CPU_COUNT
make install
make installcheck
