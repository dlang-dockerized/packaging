<?php
	use DlangDockerized\Ddct\Datatype\VersionSpecifierType;
	$legacyMakefile = match($language_level->type) {
		VersionSpecifierType::SemanticTag => ($language_level->semanticTag->minor < 107),
		VersionSpecifierType::Branch,
		VersionSpecifierType::Commit => $DTOOLS_LEGACY_MAKEFILE ?? false,
	};
?>
### Build D Tools
RUN mkdir -p d-tools
RUN tar -xf d-tools.tar.gz -C d-tools --strip-components=1
RUN make -C d-tools \
{{# if ($legacyMakefile): }}
	-f posix.mak \
{{# endif }}
	DMD=$DMD \
	all
