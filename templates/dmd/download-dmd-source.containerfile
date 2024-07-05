## Download DMD source
<?php
	$dmdGhRepoUrl    = 'https://github.com/dlang/dmd';
	$phobosGhRepoUrl = 'https://github.com/dlang/phobos';
?>
{{# if (!isset($DL_DMD_TAG)): }}
	!!! Error: $DL_DMD_TAG is not set !!!
{{# endif }}
{{# if ($DL_DMD_TAG === 'master'): }}
	<?php
		$dlDmdUrl    = "{$dmdGhRepoUrl}/archive/refs/heads/master.tar.gz";
		$dlPhobosUrl = "{$phobosGhRepoUrl}/archive/refs/heads/master.tar.gz";
	?>
{{# elseif ($DL_DMD_TAG === 'stable'): }}
	<?php
		$dlDmdUrl    = '{$dmdGhRepoUrl}/archive/refs/heads/stable.tar.gz';
		$dlPhobosUrl = '{$phobosGhRepoUrl}/archive/refs/heads/stable.tar.gz';
	?>
{{# else: }}
	<?php
		$dlDmdUrl    = "{$dmdGhRepoUrl}/archive/refs/tags/{$DL_DMD_TAG}.tar.gz";
		$dlPhobosUrl = "{$phobosGhRepoUrl}/archive/refs/tags/{$DL_DMD_TAG}.tar.gz";
	?>
{{# endif }}
RUN curl -fLsSo dmd.tar.gz "{{ $dlDmdUrl }}"
RUN curl -fLsSo phobos.tar.gz "{{ $dlPhobosUrl }}"
