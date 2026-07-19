## Build LLVM

### Unpack sources
RUN mkdir -p llvm-source llvm-build
RUN tar -xf llvm.tar.gz -C llvm-source --strip-components=1

{{# if (($semver->major >= 8) && ($semver->major <= 11)): }}
	### Fix a missing include required for modern c++ in llvm releases 8/9/10/11.
	COPY resources/patches/llvm-8-to-11-import.patch llvm-8-to-11-import.patch
	RUN patch -p1 < llvm-8-to-11-import.patch
{{# endif }}

{{# $llvmPatchVarName = "LLVM_{$semver->major}_PATCH"; }}
{{# if (isset($$llvmPatchVarName)): }}
	### Patch LLVM
	COPY resources/patches/{{ $$llvmPatchVarName }} {{ $$llvmPatchVarName }}
	RUN patch -p1 < {{ $$llvmPatchVarName }}
{{# endif }}

### Build
RUN cmake \
	-S llvm-source/llvm \
	-B llvm-build \
	-G Ninja \
	-DCMAKE_BUILD_TYPE=Release \
	-DLLVM_ENABLE_PROJECTS="clang" \
	{{# if ($semver->major >= 12): }}
		-DLLVM_ENABLE_RUNTIMES=compiler-rt \
	{{# endif }}
	{{# if (isset($LLVM_EXPERIMENTAL_TARGETS_TO_BUILD)): }}
		-DLLVM_EXPERIMENTAL_TARGETS_TO_BUILD="{{ $LLVM_EXPERIMENTAL_TARGETS_TO_BUILD }}" \
	{{# endif }}
	-DCMAKE_INSTALL_PREFIX=/opt/llvm \
	-DCMAKE_C_COMPILER=gcc \
	-DCMAKE_CXX_COMPILER=g++ \
	-DCMAKE_ASM_COMPILER=gcc
RUN cmake --build llvm-build

### Install
RUN cmake --install llvm-build

