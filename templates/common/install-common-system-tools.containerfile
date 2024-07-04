## Install common system-tools
{{# if ($DISTRO === 'debian'): }}
	RUN DEBIAN_FRONTEND=noninteractive apt-get update
	RUN apt-get -y install \
		build-essential \
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

