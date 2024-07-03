## Prepare runtime-environment
{{# if ($DISTRO === 'debian'): }}
	RUN DEBIAN_FRONTEND=noninteractive apt-get update
	RUN DEBIAN_FRONTEND=noninteractive apt-get -y install --no-install-recommends \
		{{# if (!isset($LDC_BOOT_IMAGE)): }}
			libconfig++ \
		{{# endif }}
		build-essential
	RUN rm -rf /var/lib/apt/lists/*
{{# else: }}
	!!! Unsupported distro. !!!
{{# endif }}

