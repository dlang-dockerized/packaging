<?php

$appIsLDC = ($app_name === 'ldc');
$appDependsOnLDC = (array_key_exists('ldc', $dependencies));

$ldcDependsOnLibconfig = false;

if ($appIsLDC || $appDependsOnLDC) {
	$applicableVersionLDC = ($appDependsOnLDC)
		? $dependenciesVersion['ldc']
		: $version
	;

	if ($applicableVersionLDC->isSemanticTag()) {
		$applicableSemVerLDC = $applicableVersionLDC->getValue();
		$ldcDependsOnLibconfig = (
			($applicableSemVerLDC->major === 0)
			|| (($applicableSemVerLDC->major === 1) && ($applicableSemVerLDC->minor < 3))
		);
	}
	elseif ($applicableVersionLDC->isBranch()) {
		$applicableBranchLDC = $applicableVersionLDC->getValue();
		$ldcDependsOnLibconfig = ($applicableBranchLDC->name === 'ltsmaster');
	}
}
