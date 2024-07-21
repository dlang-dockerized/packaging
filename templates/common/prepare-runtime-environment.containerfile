## Prepare runtime-environment
{{# if ($DISTRO === 'debian'): }}
	RUN DEBIAN_FRONTEND=noninteractive apt-get update
	RUN DEBIAN_FRONTEND=noninteractive apt-get -y install --no-install-recommends \
		{{# if (!isset($dependencies['ldc'])): }}
			libconfig++ \
		{{# endif }}
		build-essential \
		curl
	RUN rm -rf /var/lib/apt/lists/*
{{# else: }}
	!!! Unsupported distro. !!!
{{# endif }}

