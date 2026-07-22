<?php

$llvmVersion = ($app_name === 'llvm')
	? $version
	: $dependenciesVersion['llvm']
;

$llvmProjects = [
	'clang',
];

$llvmDependsOnLibterminfo = false;

if ($llvmVersion->isSemanticTag()) {
	$llvmSemVer = $llvmVersion->getValue();

	if ($llvmSemVer->major >= 10) {
		$llvmProjects[] = 'lld';
	}
	if ($llvmSemVer->major >= 17) {
		$llvmProjects[] = 'lldb';
	}
	if ($llvmSemVer->major < 19) {
		$llvmDependsOnLibterminfo = true;
	}
}

$llvmProjectsString = implode(';', $llvmProjects);
