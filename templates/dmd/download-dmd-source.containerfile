## Download DMD source
<?php
	$dmdGhRepoUrl          = 'https://github.com/dlang/dmd';
	$phobosGhRepoUrl       = 'https://github.com/dlang/phobos';
	if (!$druntimeMonorepo) {
		$druntimeGhRepoUrl = 'https://github.com/dlang/druntime';
	}
?>
{{# if ($version->isBranch()): }}
	<?php
		$dlDmdUrl = "{$dmdGhRepoUrl}/archive/refs/heads/{$version_string}.tar.gz";
		$dlPhobosUrl = "{$phobosGhRepoUrl}/archive/refs/heads/{$version_string}.tar.gz";
	?>
{{# elseif ($version->isCommit()): }}
	<?php
		$dlDmdUrl = "{$dmdGhRepoUrl}/archive/{$version_string}.tar.gz";
		$dlPhobosUrl = "{$phobosGhRepoUrl}/archive/{$DMD_PHOBOS_COMMIT}.tar.gz";
		if (!$druntimeMonorepo) {
			$dlDruntimeUrl = "{$druntimeGhRepoUrl}/archive/{$DMD_DRUNTIME_COMMIT}.tar.gz";
		}
	?>
{{# else: }}
	<?php
		$dlDmdUrl = "{$dmdGhRepoUrl}/archive/refs/tags/v{$version_string}.tar.gz";
		$dlPhobosUrl = "{$phobosGhRepoUrl}/archive/refs/tags/{$version_string}.tar.gz";
		if (!$druntimeMonorepo) $dlDruntimeUrl = "{$druntimeGhRepoUrl}/archive/refs/tags/{$version_string}.tar.gz";
	?>
{{# endif }}
RUN curl -fLsSo dmd.tar.gz "{{ $dlDmdUrl }}"
RUN curl -fLsSo phobos.tar.gz "{{ $dlPhobosUrl }}"
{{# if (isset($dlDruntimeUrl)): }}
	RUN curl -fLsSo druntime.tar.gz "{{ $dlDruntimeUrl }}"
{{# endif }}

