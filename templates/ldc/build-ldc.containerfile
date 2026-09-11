## Build LDC

### Unpack sources
RUN mkdir ldc-source ldc-build
RUN tar -xf ldc.tar.gz -C ldc-source --strip-components=1
RUN tar -xf phobos.tar.gz -C ldc-source/runtime/phobos --strip-components=1
{{# if (!$druntimeMonorepo): }}
	RUN tar -xf druntime.tar.gz -C ldc-source/runtime/druntime --strip-components=1
{{# endif }}

{{# if ($alchemyPatchApplicable): }}
	COPY resources/patches/ldc-alchemy-{{ $alchemyPatch }}.patch ldc-alchemy-{{ $alchemyPatch }}.patch
	RUN patch -p1 < ldc-alchemy-{{ $alchemyPatch }}.patch
{{# endif }}
{{# if ($version->isSemanticTag() && ($semver->major === 1) && ($semver->minor <= 28) && $llvmHasCompilerRT): }}
	COPY resources/patches/ldc-rt-path-1-28.patch ldc-rt-path-1-28.patch
	RUN patch -p1 < ldc-rt-path-1-28.patch
{{# endif }}


### Build
RUN cmake \
	-S ldc-source \
	-B ldc-build_-_stage-{{ $buildStageCounter }} \
	-G Ninja \
	-DCMAKE_INSTALL_PREFIX=/opt/ldc \
	-DLLVM_ROOT_DIR=/opt/llvm \
	{{# if (($buildStageCounter >= 2) && $llvmHasCompilerRT): }}
		-DBUILD_LTO_LIBS=ON \
		-DLDC_INSTALL_LTOPLUGIN=ON \
		-DLDC_INSTALL_LLVM_RUNTIME_LIBS=ON \
		{{# if ($version->isSemanticTag() && ($semver->major === 1) && ($semver->minor <= 30)): }}
			-DLDC_INSTALL_LLVM_RUNTIME_LIBS_ARCH='' \
			-DLDC_INSTALL_LLVM_RUNTIME_LIBS_OS="$(/opt/llvm/bin/clang -print-target-triple)" \
		{{# endif }}
	{{# endif }}
	{{# if (($buildStageCounter === 3) && in_array('lld', $llvmProjects) && $llvmHasCompilerRT): }}
		-DLDC_BUILD_WITH_LTO=full \
		-DCMAKE_C_COMPILER=/opt/llvm/bin/clang \
		-DCMAKE_CXX_COMPILER=/opt/llvm/bin/clang++ \
		-DCMAKE_ASM_COMPILER=gcc \
		-DCMAKE_LINKER_TYPE=LLD \
	{{# else: }}
		-DCMAKE_C_COMPILER=gcc \
		-DCMAKE_CXX_COMPILER=g++ \
		-DCMAKE_ASM_COMPILER=gcc \
	{{# endif }}
	-DCMAKE_BUILD_TYPE=RelWithDebInfo
RUN cmake --build ldc-build_-_stage-{{ $buildStageCounter }}

### Install
RUN cmake --install ldc-build_-_stage-{{ $buildStageCounter }}
ENV DMD=/opt/ldc/bin/ldmd2

