## Prepare runtime-environment
{{# if ($DISTRO === 'debian'): }}
	{{< common/enable-old-ubuntu-releases-repo.containerfile }}
	{{< common/ldc-dependencies.php }}

	### Install packages
	RUN DEBIAN_FRONTEND=noninteractive apt-get update
	RUN DEBIAN_FRONTEND=noninteractive apt-get -y install --no-install-recommends \
		{{# if ($ldcDependsOnLibconfig): }}
			libconfig-dev \
		{{# endif }}
		build-essential \
		curl \
		{{# if (isset($llvmProjects) && in_array('lldb', $llvmProjects)): }}
			"$(apt-cache search -n 'libpython3\.[0-9]+$' | sed 's/ .*//')" \
			"$(apt-cache search -n 'libedit[0-9]+$' | sed 's/ .*//')" \
			"$(apt-cache search -n 'libncurses[0-9]+$' | sed 's/ .*//')" \
		{{# endif }}
		libcurl4-openssl-dev
	RUN rm -rf /var/lib/apt/lists/*
{{# else: }}
	!!! Unsupported distro. !!!
{{# endif }}

