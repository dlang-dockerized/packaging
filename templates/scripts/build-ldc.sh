#!/bin/sh
set -e

# Unpack sources
mkdir ldc-source ldc-build
tar -xf ldc.tar.gz -C ldc-source --strip-components=1
tar -xf phobos.tar.gz -C ldc-source/runtime/phobos --strip-components=1
[ -f druntime.tar.gz ] && tar -xf druntime.tar.gz -C ldc-source/runtime/druntime --strip-components=1

# Build
cmake \
	-S ldc-source \
	-B ldc-build \
	-G Ninja \
	-DCMAKE_BUILD_TYPE=Release \
	-DCMAKE_INSTALL_PREFIX=/opt/ldc \
	-DLLVM_ROOT_DIR=/opt/llvm \
	-DCMAKE_C_COMPILER=gcc \
	-DCMAKE_CXX_COMPILER=g++ \
	-DCMAKE_ASM_COMPILER=gcc
	#-DLDC_EXE=y # didn't work
cmake --build ldc-build

# Install
cmake --install ldc-build
