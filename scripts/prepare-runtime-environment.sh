#!/bin/sh
set -e

if [ -z "$DISTRO" ]; then
	. /etc/os-release
	DISTRO=$ID
fi

echo "System is '$DISTRO'"

if
	[ "$DISTRO" = "debian" ] ||
	[ "$DISTRO" = "ubuntu" ] ||
	[ "$DISTRO" = "linuxmint" ]
then
	export DEBIAN_FRONTEND=noninteractive
	apt-get update
	apt-get -y install --no-install-recommends build-essential
	[ -z "$LDC_BOOT_IMAGE" ] && apt-get -y install --no-install-recommends libconfig++
	rm -rf /var/lib/apt/lists/*
else
	echo 'Unsupported distro.'
	exit 1
fi
