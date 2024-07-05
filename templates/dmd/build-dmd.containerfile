## Build DMD
<?php
	$druntimeMonorepo = ($DMD_SEMVER_MINOR >= 101);
	$legacyMakefile = ($DMD_SEMVER_MINOR < 107);
?>

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

### Build DMD compiler
{{# if ($legacyMakefile): }}
	RUN make -C dmd -f posix.mak
{{# else: }}
	RUN make -C dmd
{{# endif }}

RUN rm /usr/bin/dmd
RUN ln -s /opt/build/dmd/generated/linux/release/64/dmd /usr/bin/dmd
ENV DMD=/usr/bin/dmd

### Build Phobos
{{# if ($legacyMakefile): }}
	RUN make -C phobos -f posix.mak
{{# else: }}
	RUN make -C phobos
{{# endif }}
