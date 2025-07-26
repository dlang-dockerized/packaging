#### Download CMake sources
{{# if ($CMAKE_BOOTSTRAP === 'v2'): }}
	RUN curl -fLsSo cmake.tar.gz 'https://cmake.org/files/v2.8/cmake-2.8.12.2.tar.gz'
	RUN echo '8c6574e9afabcb9fc66f463bb1f2f051958d86c85c37fccf067eb1a44a120e5e  cmake.tar.gz' | shasum -a256 -c
{{# elseif ($CMAKE_BOOTSTRAP === 'v3-C++0x'): }}
	RUN curl -fLsSo cmake.tar.gz 'https://cmake.org/files/v3.9/cmake-3.9.6.tar.gz'
	RUN echo '7410851a783a41b521214ad987bb534a7e4a65e059651a2514e6ebfc8f46b218  cmake.tar.gz' | shasum -a256 -c
{{# elseif ($CMAKE_BOOTSTRAP === 'v3'): }}
	RUN curl -fLsSo cmake.tar.gz 'https://cmake.org/files/v3.31/cmake-3.31.8.tar.gz'
	RUN echo 'e3cde3ca83dc2d3212105326b8f1b565116be808394384007e7ef1c253af6caa  cmake.tar.gz' | shasum -a256 -c
{{# else: }}
	!!! Error: Unsupported CMake version requested: `{{$CMAKE_BOOTSTRAP}}` !!!
{{# endif }}

