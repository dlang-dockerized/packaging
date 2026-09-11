<?php

use DlangDockerized\Ddct\Datatype\VersionSpecifierType;

$isBootstrappedByLDC = isset($dependencies['ldc']);

$druntimeMonorepo = match($version->type) {
	VersionSpecifierType::SemanticTag => (($semver->major === 1) && ($semver->minor >= 31)),
	VersionSpecifierType::Branch => ($branch->name !== 'ltsmaster'),
	VersionSpecifierType::Commit => $LDC_DRUNTIME_COMMIT ?? false,
};

// Unfortunately, branch names of LDC are inconsistent.
// Its main branch lacks the `ldc-` prefix.
if ($version->isBranch()) {
	$phobosBranch = ($branch->name === 'master')
		? 'ldc'
		: 'ldc-' . $branch->name;

	if (!$druntimeMonorepo) {
		$druntimeBranch = ($branch->name === 'master')
		? 'ldc'
		: 'ldc-' . $branch->name;
	}
}

$alchemyPatchApplicable = (
	$version->isSemanticTag()
	&& ($semver->major === 1)
	&& ($semver->minor >= 13)
	&& ($semver->minor < 29)
);

if ($alchemyPatchApplicable) {
	$alchemyPatch = (function () use ($semver) {
		if ($semver->minor >= 25) {
			return '1-25';
		}
		if ($semver->minor >= 22) {
			return '1-22';
		}
		if ($semver->minor >= 21) {
			return '1-21';
		}	
		return '1-13';
	})();
}
