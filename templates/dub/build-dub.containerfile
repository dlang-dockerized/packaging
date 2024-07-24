## Build DUB

### Unpack sources
RUN mkdir -p dub
RUN tar -xf dub.tar.gz -C dub --strip-components=1

### Build
WORKDIR /opt/build/dub
{{# if (isset($DUB_USE_BUILD_SH)): }}
	{{# if ($DISTRO === 'debian'): }}
		RUN DEBIAN_FRONTEND=noninteractive apt-get update
		RUN DEBIAN_FRONTEND=noninteractive apt-get -y install git
		RUN rm -rf /var/lib/apt/lists/*
	{{# endif }}
	RUN ./build.sh
{{# else: }}
	RUN DFLAGS="-O -inline" $DMD -run build.d
{{# endif }}
WORKDIR /opt/build

