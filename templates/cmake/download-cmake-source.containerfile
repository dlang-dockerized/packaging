#### Download CMake sources
{{# if ((string)$CMAKE_BOOTSTRAP === '2'): }}
	RUN curl -fLsSo cmake.tar.gz 'https://cmake.org/files/v2.8/cmake-2.8.12.2.tar.gz'
	RUN echo '8c6574e9afabcb9fc66f463bb1f2f051958d86c85c37fccf067eb1a44a120e5e  cmake.tar.gz' | shasum -a256 -c
{{# else: }}
	!!! Error: Unsupported CMake version `{{$CMAKE_BOOTSTRAP}}` !!!
{{# endif }}

