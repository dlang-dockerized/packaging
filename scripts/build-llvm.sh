#!/bin/sh
set -e

if [ -z "$LLVM_SEMVER_MAJOR" ]; then
	echo "Error: \$LLVM_SEMVER_MAJOR is not set"
	exit 1
fi

# Unpack sources
mkdir -p llvm-source llvm-build
tar -xf llvm.tar.gz -C llvm-source --strip-components=1

if [ 8 -le "$LLVM_SEMVER_MAJOR" ] && [ "$LLVM_SEMVER_MAJOR" -le 11 ]; then
	# Fix a missing include required for modern c++ in llvm releases 8/9/10/11.
	cd llvm-source
	curl "https://github.com/llvm/llvm-project/commit/b498303066a63a203d24f739b2d2e0e56dca70d1.patch" | patch -p1
	cd ..
fi

# Build
cmake \
	-S llvm-source/llvm \
	-B llvm-build \
	-G Ninja \
	-DCMAKE_BUILD_TYPE=Release \
	-DLLVM_ENABLE_PROJECTS="clang" \
	$(if [ $LLVM_SEMVER_MAJOR -ge 12 ]; then echo -n '-DLLVM_ENABLE_RUNTIMES=compiler-rt'; fi) \
	-DCMAKE_INSTALL_PREFIX=/opt/llvm \
	-DCMAKE_C_COMPILER=gcc \
	-DCMAKE_CXX_COMPILER=g++ \
	-DCMAKE_ASM_COMPILER=gcc
cmake --build llvm-build

# Install
cmake --install llvm-build
