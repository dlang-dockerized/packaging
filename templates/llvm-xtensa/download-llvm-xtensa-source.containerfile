## Download LLVM source

{{# if (!isset($GIT_TAG)): }}
	!!! Error: $GIT_TAG is not set !!!
{{# else: }}
    RUN curl -fLsSo llvm.tar.gz "https://github.com/espressif/llvm-project/archive/refs/tags/{{ $GIT_TAG }}.tar.gz"
{{# endif }}
