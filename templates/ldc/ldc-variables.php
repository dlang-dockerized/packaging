<?php

use DlangDockerized\Ddct\Datatype\VersionSpecifierType;

$isBootstrappedByLDC = isset($dependencies['ldc']);

$druntimeMonorepo = match($version->type) {
	VersionSpecifierType::SemanticTag => (($semver->major === 1) && ($semver->minor >= 31)),
	VersionSpecifierType::Branch => $LDC_DRUNTIME_MONOREPO ?? false,
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
