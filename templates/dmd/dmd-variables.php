<?php

use DlangDockerized\Ddct\Datatype\VersionSpecifierType;

$dmdBuildD = match($version->type) {
	VersionSpecifierType::SemanticTag => ($version->semanticTag->minor >= 82),
	VersionSpecifierType::Branch,
	VersionSpecifierType::Commit => $DMD_NO_BUILDD ?? true,
};

$dmdPgoMakefile = match($version->type) {
	VersionSpecifierType::SemanticTag => (
		($version->semanticTag->minor >= 114) ||
		($version->semanticTag->minor == 113) && ($version->semanticTag->patch >= 1)
	),
	VersionSpecifierType::Branch,
	VersionSpecifierType::Commit => $DMD_NO_PGO_MAKEFILE ?? true,
};

$druntimeMonorepo = match($version->type) {
	VersionSpecifierType::SemanticTag => ($version->semanticTag->minor >= 101),

	VersionSpecifierType::Branch => true,
	VersionSpecifierType::Commit => $DMD_DRUNTIME_COMMIT ?? false,
};

$legacyMakefile = match($version->type) {
	VersionSpecifierType::SemanticTag => ($version->semanticTag->minor < 107),
	VersionSpecifierType::Branch,
	VersionSpecifierType::Commit => $DMD_LEGACY_MAKEFILE ?? false,
};

if (!$dependenciesVersion['ldc']->isSemanticTag()) {
	throw new \Exception('These templates only support LDC versions in the form of semantic tags.');
}
$ldcVersion = $dependenciesVersion['ldc']->getValue();
