<?php

use DlangDockerized\Ddct\Datatype\VersionSpecifierType;

$druntimeMonorepo = match($version->type) {
	VersionSpecifierType::SemanticTag => ($version->semanticTag->minor >= 101),

	VersionSpecifierType::Branch => $DMD_DRUNTIME_MONOREPO ?? false,
	VersionSpecifierType::Commit => $DMD_DRUNTIME_COMMIT ?? false,
};

$legacyMakefile = match($version->type) {
	VersionSpecifierType::SemanticTag => ($version->semanticTag->minor < 107),
	VersionSpecifierType::Branch,
	VersionSpecifierType::Commit => $DMD_LEGACY_MAKEFILE ?? false,
};

$legacyBinDir = (
	($semver->major < 2)
	|| (
		($semver->major === 2) &&
		($semver->minor < 74)
	)
);