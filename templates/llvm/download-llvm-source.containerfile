## Download LLVM source
{{# if (!isset($DL_LLVM_TAG)): }}
	!!! Error: $DL_LLVM_TAG is not set !!!
{{# else: }}
	RUN curl -fLsSo llvm.tar.gz \
		{{# if ($DL_LLVM_TAG === 'main'): }}
			"https://github.com/llvm/llvm-project/archive/refs/heads/main.tar.gz"
		{{# else: }}
			"https://github.com/llvm/llvm-project/archive/refs/tags/{{ $DL_LLVM_TAG }}.tar.gz"
		{{# endif }}
{{# endif }}

