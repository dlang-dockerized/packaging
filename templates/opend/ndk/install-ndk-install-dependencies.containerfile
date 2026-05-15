#### Install installation dependencies of Android NDK
{{# if ($DISTRO === 'debian'): }}
	RUN DEBIAN_FRONTEND=noninteractive apt-get update
	RUN apt-get -y install \
		unzip
	RUN rm -rf /var/lib/apt/lists/*
{{# endif }}

