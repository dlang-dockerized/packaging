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
	apt-get -y install \
		cmake python3 \
		ninja-build
	rm -rf /var/lib/apt/lists/*
fi
