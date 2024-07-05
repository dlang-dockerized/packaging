## Download DMD source
<?php
	$dmdGhRepoUrl    = 'https://github.com/dlang/dmd';
	$phobosGhRepoUrl = 'https://github.com/dlang/phobos';

	$druntimeMonorepo = ($DMD_SEMVER_MINOR >= 101);
	if (!$druntimeMonorepo) $druntimeGhRepoUrl = 'https://github.com/dlang/druntime';
?>
{{# if (isset($dmd_override_branch)): }}
	<?php
		$dlDmdUrl    = "{$dmdGhRepoUrl}/archive/refs/heads/{$dmd_override_branch}.tar.gz";
		$dlPhobosUrl = "{$phobosGhRepoUrl}/archive/refs/heads/{$dmd_override_branch}.tar.gz";
	?>
{{# else: }}
	<?php
		$dlDmdUrl    = "{$dmdGhRepoUrl}/archive/refs/tags/{$DL_DMD_TAG}.tar.gz";
		$dlPhobosUrl = "{$phobosGhRepoUrl}/archive/refs/tags/{$DL_DMD_TAG}.tar.gz";
		if (!$druntimeMonorepo) $dlDruntimeUrl = "{$druntimeGhRepoUrl}/archive/refs/tags/{$DL_DMD_TAG}.tar.gz";
	?>
{{# endif }}
RUN curl -fLsSo dmd.tar.gz "{{ $dlDmdUrl }}"
RUN curl -fLsSo phobos.tar.gz "{{ $dlPhobosUrl }}"
{{# if (!$druntimeMonorepo): }}
	RUN curl -fLsSo druntime.tar.gz "{{ $dlDruntimeUrl }}"
{{# endif }}

