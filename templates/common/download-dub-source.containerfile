## Download DUB source
{{# if (!isset($DL_DUB_TAG)): }}
	!!! Error: $DL_DUB_TAG is not set !!!
{{# else: }}
	RUN curl -fLsSo dub.tar.gz \
		{{# if($DL_DUB_TAG === 'stable'): }}
			"https://github.com/dlang/dub/archive/refs/heads/stable.tar.gz"
		{{# else: }}
			"https://github.com/dlang/dub/archive/refs/tags/{{ $DL_DUB_TAG }}.tar.gz"
		{{# endif }}
{{# endif }}

