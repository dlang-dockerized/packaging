<?php

$llvmVersion = ($app_name === 'llvm')
	? $version
	: $dependenciesVersion['llvm']
;

$llvmProjects = [
	'clang',
];

$llvmDependsOnLibterminfo = false;
$llvmHasCompilerRT = false;

if (!$llvmVersion->isSemanticTag()) {
	throw new \Exception('These templates only support LLVM versions in the form of semantic tags.');
}

if ($llvmVersion->isSemanticTag()) {
	$llvmSemVer = $llvmVersion->getValue();

	if ($llvmSemVer->major >= 12) {
		$llvmHasCompilerRT = true;
	}
	if ($llvmSemVer->major >= 14) {
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
