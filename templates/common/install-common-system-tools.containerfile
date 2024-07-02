# install common system-tools
{{# if ($DISTRO === 'debian'): }}
	RUN DEBIAN_FRONTEND=noninteractive apt-get update
	RUN apt-get -y install \
		build-essential \
		curl
	RUN rm -rf /var/lib/apt/lists/*
{{# elseif ($DISTRO === 'fedora'): }}
{{# endif }}
