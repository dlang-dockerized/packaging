##### Install dependencies of Emscripten SDK
{{# if ($DISTRO === 'debian'): }}
	RUN DEBIAN_FRONTEND=noninteractive apt-get update
	RUN apt-get -y install \
		python3
	RUN rm -rf /var/lib/apt/lists/*
{{# endif }}

