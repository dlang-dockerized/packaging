## Install LDC build deps
{{# if ($DISTRO === 'debian'): }}
	RUN DEBIAN_FRONTEND=noninteractive apt-get update
	RUN DEBIAN_FRONTEND=noninteractive apt-get -y install \
		cmake python3 \
		ninja-build \
		libconfig++-dev # libconfig++ only needed for older ldc
	RUN rm -rf /var/lib/apt/lists/*
{{# endif }}

