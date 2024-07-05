{{# if (!isset($DL_LDC_TAG)): }}
	!!! Error: $DL_LDC_TAG is not set !!!
{{# elseif (!isset($LDC_SEMVER_MAJOR)): }}
	!!! Error: $LDC_SEMVER_MAJOR is not set !!!
{{# elseif (!isset($LDC_SEMVER_MINOR)): }}
	!!! Error: $LDC_SEMVER_MINOR is not set !!!
{{# else: }}
	### Download LDC source
	RUN curl -fLsSo ldc.tar.gz \
		{{# if ($DL_LDC_TAG === 'master'): }}
			"https://github.com/ldc-developers/ldc/archive/refs/heads/master.tar.gz"
		{{# elseif ($DL_LDC_TAG === 'ltsmaster'): }}
			"https://github.com/ldc-developers/ldc/archive/refs/heads/ltsmaster.tar.gz"
		{{# else: }}
			"https://github.com/ldc-developers/ldc/archive/refs/tags/{{ $DL_LDC_TAG }}.tar.gz"
		{{# endif }}

	### Download Phobos source
	RUN curl -fLsSo phobos.tar.gz \
		{{# if ($DL_LDC_TAG === 'master'): }}
			"https://github.com/ldc-developers/phobos/archive/refs/heads/ldc.tar.gz"
		{{# elseif ($DL_LDC_TAG === 'ltsmaster'): }}
			"https://github.com/ldc-developers/phobos/archive/refs/heads/ldc-ltsmaster.tar.gz"
		{{# else: }}
			"https://github.com/ldc-developers/phobos/archive/refs/tags/ldc-{{ $DL_LDC_TAG }}.tar.gz"
		{{# endif }}

	{{# if (($LDC_SEMVER_MAJOR == 0) || (($LDC_SEMVER_MAJOR == 1) && ($LDC_SEMVER_MINOR <= 30))): }}
		### Download separate druntime source (old repo layout)
		RUN curl -fLsSo druntime.tar.gz \
			{{# if ($DL_LDC_TAG === 'master'): }}
			 	"https://github.com/ldc-developers/druntime/archive/refs/heads/ldc.tar.gz"
			{{# elseif ($DL_LDC_TAG === 'ltsmaster'): }}
				"https://github.com/ldc-developers/druntime/archive/refs/heads/ldc-ltsmaster.tar.gz"
			{{# else: }}
				"https://github.com/ldc-developers/druntime/archive/refs/tags/ldc-{{ $DL_LDC_TAG }}.tar.gz"
			{{# endif }}
	{{# endif }}

{{# endif }}

