### Download LDC source
RUN curl -fLsSo ldc.tar.gz \
	{{# if ($version->isBranch()): }}
		"https://github.com/ldc-developers/ldc/archive/refs/heads/{{ $branch }}.tar.gz"
	{{# elseif ($version->isCommit()): }}
		"https://github.com/ldc-developers/ldc/archive/{{ $commit }}.tar.gz"
	{{# else: }}
		"https://github.com/ldc-developers/ldc/archive/refs/tags/v{{ $version_string }}.tar.gz"
	{{# endif }}

### Download Phobos source
RUN curl -fLsSo phobos.tar.gz \
	{{# if ($version->isBranch()): }}
		"https://github.com/ldc-developers/phobos/archive/refs/heads/{{ $phobosBranch }}.tar.gz"
	{{# elseif ($version->isCommit()): }}
		"https://github.com/ldc-developers/phobos/archive/{{ $LDC_PHOBOS_COMMIT }}.tar.gz"
	{{# else: }}
		"https://github.com/ldc-developers/phobos/archive/refs/tags/ldc-v{{ $version_string }}.tar.gz"
	{{# endif }}

{{# if (!$druntimeMonorepo): }}
	### Download separate druntime source (old repo layout)
	RUN curl -fLsSo druntime.tar.gz \
		{{# if ($version->isBranch()): }}
			"https://github.com/ldc-developers/druntime/archive/refs/heads/{{ $druntimeBranch }}.tar.gz"
		{{# elseif ($version->isCommit()): }}
			"https://github.com/ldc-developers/druntime/archive/{{ $LDC_DRUNTIME_COMMIT }}.tar.gz"
		{{# else: }}
			"https://github.com/ldc-developers/druntime/archive/refs/tags/ldc-v{{ $version_string }}.tar.gz"
		{{# endif }}
{{# endif }}

