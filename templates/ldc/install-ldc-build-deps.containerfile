## Install LDC build deps
{{# if ($DISTRO === 'debian'): }}
	RUN DEBIAN_FRONTEND=noninteractive apt-get update
	RUN DEBIAN_FRONTEND=noninteractive apt-get -y install \
		{{# if (!isset($CMAKE_BOOTSTRAP)): }}
			cmake \
		{{# endif }}
		{{# if (!isset($NINJA_BOOTSTRAP)): }}
			ninja-build \
		{{# endif }}
		python3 \
		libconfig++-dev # libconfig++ only needed for older ldc
	RUN rm -rf /var/lib/apt/lists/*
{{# endif }}

{{< cmake/setup-cmake.containerfile }}
{{< ninja/setup-ninja.containerfile }}
