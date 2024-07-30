{{# if (isset($extendedSystemTools)): }}
	## Install extended common system-tools
{{# else: }}
	## Install common system-tools
{{# endif }}
{{# if ($DISTRO === 'debian'): }}
	RUN DEBIAN_FRONTEND=noninteractive apt-get update
	RUN apt-get -y install \
		build-essential \
		{{# if (isset($extendedSystemTools)): }}
			git \
			libcurl4-openssl-dev \
		{{# endif }}
		curl
	RUN rm -rf /var/lib/apt/lists/*
{{# elseif ($DISTRO === 'fedora'): }}
	RUN dnf -y update
	RUN dnf -y install \
		gcc \
		curl-minimal \
		gzip \
		tar \
		xz
{{# endif }}
{{# if (isset($extendedSystemTools)): }}
	{{# unset($extendedSystemTools) }}
{{# endif }}

