## Download LLVM source
RUN curl -fLsSo llvm.tar.gz \
	{{# if ($version->isBranch()): }}
		"https://github.com/llvm/llvm-project/archive/refs/heads/{{ $version_string }}.tar.gz"
	{{# elseif ($version->isCommit()): }}
		"https://github.com/llvm/llvm-project/archive/{{ $version_string }}.tar.gz"
	{{# else: }}
		"https://github.com/llvm/llvm-project/archive/refs/tags/llvmorg-{{ $version_string }}.tar.gz"
	{{# endif }}

