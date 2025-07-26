{{# if (isset($NINJA_BOOTSTRAP)): }}
	### Setup Ninja
	RUN git clone 'https://github.com/ninja-build/ninja.git'
	WORKDIR /opt/build/ninja
	RUN git checkout '{{ $NINJA_BOOTSTRAP }}'
	RUN cmake -Bbuild-cmake -DBUILD_TESTING=OFF
	RUN cmake --build build-cmake
	WORKDIR /opt/build
	RUN mv /opt/build/ninja/build-cmake/ninja /usr/local/bin/ninja

{{# endif }}
