## Build DMD

### Unpack sources
RUN mkdir -p dmd
RUN mkdir -p phobos
RUN tar -xf dmd.tar.gz -C dmd --strip-components=1
RUN tar -xf phobos.tar.gz -C phobos --strip-components=1

### Build DMD compiler
{{# if ($DMD_SEMVER_MINOR < 107): }}
	RUN make -C dmd -f posix.mak
{{# else: }}
	RUN make -C dmd
{{# endif }}

RUN rm /usr/bin/dmd
RUN ln -s /opt/build/dmd/generated/linux/release/64/dmd /usr/bin/dmd
ENV DMD=/usr/bin/dmd

### Build Phobos
RUN make -C phobos -f posix.mak

