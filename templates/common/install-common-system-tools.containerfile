{{# if (isset($extendedSystemTools)): }}
	## Install extended common system-tools
{{# else: }}
	## Install common system-tools
{{# endif }}
{{< common/enable-old-ubuntu-releases-repo.containerfile }}

### Install packages
RUN DEBIAN_FRONTEND=noninteractive apt-get update
RUN apt-get -y install \
	{{# if (isset($extendedSystemTools)): }}
	{{# endif }}
	build-essential \
	curl \
	git \
	libcurl4-openssl-dev
RUN rm -rf /var/lib/apt/lists/*
{{# if (isset($extendedSystemTools)): }}
	{{# unset($extendedSystemTools) }}
{{# endif }}

