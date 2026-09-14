## Build DMD

### Unpack sources
RUN mkdir -p dmd
RUN mkdir -p phobos
{{# if (!$druntimeMonorepo): }}
	RUN mkdir -p druntime
{{# endif }}
RUN tar -xf dmd.tar.gz -C dmd --strip-components=1
RUN tar -xf phobos.tar.gz -C phobos --strip-components=1
{{# if (!$druntimeMonorepo): }}
	RUN tar -xf druntime.tar.gz -C druntime --strip-components=1
{{# endif }}

{{# if ($dmdBuildD): }}
	### Patch build script
	COPY resources/patches/wrap-std-process-execute.d wrap-std-process-execute.d
	{{# if ($druntimeMonorepo): }}
		RUN cat wrap-std-process-execute.d >> dmd/compiler/src/build.d
	{{# else: }}
		RUN cat wrap-std-process-execute.d >> dmd/src/build.d
	{{# endif }}
{{# endif }}

### Build DMD compiler
{{# if ($dmdBuildD): }}
	RUN \
		{{# if (($ldcVersion->major >= 2) || (($ldcVersion->major === 1) && ($ldcVersion->minor >= 30))): }}
			ENABLE_LTO=1 \
			ENABLE_RELEASE=1 \
		{{# endif }}
		HOST_DMD=/opt/ldc/bin/ldmd2 \
		/opt/ldc/bin/ldmd2 -run \
		{{# if ($druntimeMonorepo): }}
			./dmd/compiler/src/build.d \
		{{# else: }}
			./dmd/src/build.d \
		{{# endif }}
			-- dmd
{{# elseif ($legacyMakefile): }}
	RUN make -C dmd -f posix.mak
{{# else: }}
	RUN make -C dmd
{{# endif }}

RUN unlink /usr/local/bin/dmd
RUN ln -s /opt/build/dmd/generated/linux/release/64/dmd /usr/local/bin/dmd
ENV DMD=/usr/local/bin/dmd

### Build Phobos
{{# if ($legacyMakefile): }}
	RUN make -C phobos -f posix.mak
{{# else: }}
	RUN make -C phobos
{{# endif }}

{{# if ($dmdBuildD && (($ldcVersion->major >= 2) || (($ldcVersion->major === 1) && ($ldcVersion->minor >= 30)))): }}
	### Rebuild DMD with PGO
	RUN ln -s /opt/ldc/bin/ldc-profdata /usr/local/bin/ldc-profdata
	WORKDIR /opt/build/dmd
	RUN \
		ENABLE_RELEASE=1 \
		HOST_DMD=/opt/ldc/bin/ldmd2 \
		/opt/ldc/bin/ldmd2 -run \
		{{# if ($druntimeMonorepo): }}
			./compiler/src/build.d \
		{{# else: }}
			./src/build.d \
		{{# endif }}
			-- --force dmd-pgo
	WORKDIR /opt/build

	#### Rebuild druntime + Phobos
	RUN find phobos -type f -name '*.d' -exec touch {} \;
	{{# if ($druntimeMonorepo): }}
		RUN find dmd/druntime/src -type f -name '*.d' -exec touch {} \;
	{{# else: }}
		RUN find druntime/src -type f -name '*.d' -exec touch {} \;
	{{# endif }}
	{{# if ($legacyMakefile): }}
		RUN make -C phobos -f posix.mak
	{{# else: }}
		RUN make -C phobos
	{{# endif }}
{{# endif }}

