## Install LLVM build deps
{{# if ($DISTRO === 'debian'): }}
	RUN DEBIAN_FRONTEND=noninteractive apt-get update
	RUN DEBIAN_FRONTEND=noninteractive apt-get -y install \
		{{# if (!isset($CMAKE_BOOTSTRAP)): }}
			cmake \
		{{# endif }}
		{{# if (!isset($NINJA_BOOTSTRAP)): }}
			ninja-build \
		{{# endif }}
		python3
	### LLDB build deps
	RUN DEBIAN_FRONTEND=noninteractive apt-get -y install \
		libedit-dev \
		libeditreadline-dev \
		libncurses-dev \
		python3-dev \
		{{# if ($semver->major >= 7): }}
			{{# if (!isset($LLDB_NO_SETUPTOOLS)): }}
				python3-setuptools \
			{{# endif }}
			{{# if (!isset($LLDB_NO_ZOMBIEIMP)): }}
				python3-zombie-imp \
			{{# endif }}
		{{# endif }}
		swig
	RUN rm -rf /var/lib/apt/lists/*
{{# endif }}

{{< cmake/setup-cmake.containerfile }}
{{< ninja/setup-ninja.containerfile }}
