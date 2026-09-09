## Install common system-tools
{{< common/enable-old-ubuntu-releases-repo.containerfile }}

### Install packages
RUN DEBIAN_FRONTEND=noninteractive apt-get update
RUN apt-get -y install \
	build-essential \
	curl \
	git \
	libcurl4-openssl-dev
RUN rm -rf /var/lib/apt/lists/*

