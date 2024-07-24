## Install DMD build deps
{{# if ($DISTRO === 'debian'): }}
	RUN DEBIAN_FRONTEND=noninteractive apt-get update
	RUN DEBIAN_FRONTEND=noninteractive apt-get -y install \
		libconfig++-dev # libconfig++ only needed for older ldc
	RUN rm -rf /var/lib/apt/lists/*
{{# endif }}

