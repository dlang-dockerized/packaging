<?php

$llvmProjects = [
	'clang',
];

if ($version->isSemanticTag()) {
	if ($semver->major >= 10) {
		$llvmProjects[] = 'lld';
	}
	if ($semver->major >= 17) {
		$llvmProjects[] = 'lldb';
	}
}

$llvmProjectsString = implode(';', $llvmProjects);
