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

{{# if (!$version->isSemanticTag() || $semver->minor >= 82): }}
	### Patch build script
	COPY resources/patches/wrap-std-process-execute.d wrap-std-process-execute.d
	{{# if ($druntimeMonorepo): }}
		RUN cat wrap-std-process-execute.d >> dmd/compiler/src/build.d
	{{# else: }}
		RUN cat wrap-std-process-execute.d >> dmd/src/build.d
	{{# endif }}
{{# endif }}

### Build DMD compiler
{{# if ($legacyMakefile): }}
	RUN make -C dmd -f posix.mak
{{# else: }}
	RUN make -C dmd
{{# endif }}

RUN rm /usr/local/bin/dmd
RUN ln -s /opt/build/dmd/generated/linux/release/64/dmd /usr/local/bin/dmd
ENV DMD=/usr/local/bin/dmd

### Build Phobos
{{# if ($legacyMakefile): }}
	RUN make -C phobos -f posix.mak
{{# else: }}
	RUN make -C phobos
{{# endif }}
