## Download DUB source
{{# if (!isset($extras['dub'])): }}
	!!! Error: $extras['dub'] is not set !!!
{{# else: }}
	RUN curl -fLsSo dub.tar.gz \
		{{# if ($extras['dub']->isSemanticTag()): }}
			"https://github.com/dlang/dub/archive/refs/tags/v{{ $extras['dub'] }}.tar.gz"
		{{# elseif ($extras['dub']->isBranch()): }}
			"https://github.com/dlang/dub/archive/refs/heads/{{ $extras['dub'] }}.tar.gz"
		{{# elseif ($extras['dub']->isCommit()): }}
			"https://github.com/dlang/dub/archive/{{ $extras['dub'] }}.tar.gz"
		{{# endif }}
{{# endif }}

