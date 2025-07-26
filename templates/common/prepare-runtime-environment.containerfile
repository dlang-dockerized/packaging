## Prepare runtime-environment
{{# if ($DISTRO === 'debian'): }}
	{{< common/enable-old-ubuntu-releases-repo.containerfile }}

	### Install packages
	RUN DEBIAN_FRONTEND=noninteractive apt-get update
	RUN DEBIAN_FRONTEND=noninteractive apt-get -y install --no-install-recommends \
		{{# if (!isset($dependencies['ldc'])): }}
			libconfig++ \
		{{# endif }}
		build-essential \
		curl \
		libcurl4-openssl-dev
	RUN rm -rf /var/lib/apt/lists/*
{{# else: }}
	!!! Unsupported distro. !!!
{{# endif }}

