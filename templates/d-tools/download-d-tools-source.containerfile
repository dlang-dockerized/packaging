### Download D Tools source
<?php
	use DlangDockerized\Ddct\Datatype\VersionSpecifierType;
	$dToolsGhRepoUrl = 'https://github.com/dlang/tools';
	$dlDToolsUrl = match($version->type) {
		VersionSpecifierType::SemanticTag => "{$dToolsGhRepoUrl}/archive/refs/tags/v{$language_level_string}.tar.gz",
		VersionSpecifierType::Commit => "{$dToolsGhRepoUrl}/archive/{$DTOOLS_COMMIT}.tar.gz",
		VersionSpecifierType::Branch => "{$dToolsGhRepoUrl}/archive/refs/heads/{$language_level_string}.tar.gz",
	}
?>
RUN curl -fLsSo d-tools.tar.gz "{{ $dlDToolsUrl }}"
