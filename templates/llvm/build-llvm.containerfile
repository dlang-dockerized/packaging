## Build LLVM

{{# if (!isset($LLVM_SEMVER_MAJOR)): }}
	!!! Error: $LLVM_SEMVER_MAJOR is not set !!!
{{# else: }}
	### Unpack sources
	RUN mkdir -p llvm-source llvm-build
	RUN tar -xf llvm.tar.gz -C llvm-source --strip-components=1

	{{# if (($LLVM_SEMVER_MAJOR >= 8) && ($LLVM_SEMVER_MAJOR <= 11)): }}
		### Fix a missing include required for modern c++ in llvm releases 8/9/10/11.
		WORKDIR /opt/build/llvm-source
		RUN curl "https://github.com/llvm/llvm-project/commit/b498303066a63a203d24f739b2d2e0e56dca70d1.patch" | patch -p1
		WORKDIR /opt/build
	{{# endif }}

	### Build
	RUN cmake \
		-S llvm-source/llvm \
		-B llvm-build \
		-G Ninja \
		-DCMAKE_BUILD_TYPE=Release \
		-DLLVM_ENABLE_PROJECTS="clang" \
		{{# if ($LLVM_SEMVER_MAJOR >= 12): }}
			-DLLVM_ENABLE_RUNTIMES=compiler-rt \
		{{# endif }}
		-DCMAKE_INSTALL_PREFIX=/opt/llvm \
		-DCMAKE_C_COMPILER=gcc \
		-DCMAKE_CXX_COMPILER=g++ \
		-DCMAKE_ASM_COMPILER=gcc
	RUN cmake --build llvm-build

	### Install
	RUN cmake --install llvm-build
{{# endif }}

