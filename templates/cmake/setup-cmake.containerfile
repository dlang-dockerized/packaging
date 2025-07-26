{{# if (isset($CMAKE_BOOTSTRAP)): }}
	### Setup CMake

	{{< cmake/download-cmake-source.containerfile }}

	{{< cmake/build-cmake.containerfile }}

{{# endif }}
