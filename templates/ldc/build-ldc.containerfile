## Build LDC

### Unpack sources
RUN mkdir ldc-source ldc-build
RUN tar -xf ldc.tar.gz -C ldc-source --strip-components=1
RUN tar -xf phobos.tar.gz -C ldc-source/runtime/phobos --strip-components=1
{{# if (($LDC_SEMVER_MAJOR == 0) || (($LDC_SEMVER_MAJOR == 1) && ($LDC_SEMVER_MINOR <= 30))): }}
	RUN tar -xf druntime.tar.gz -C ldc-source/runtime/druntime --strip-components=1
{{# endif }}

### Build
RUN cmake \
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
RUN cmake --build ldc-build

### Install
RUN cmake --install ldc-build
ENV DMD=/opt/ldc/bin/ldmd2

