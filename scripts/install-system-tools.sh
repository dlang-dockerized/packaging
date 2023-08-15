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
		curl \
		tar \
		gzip \
		build-essential \
		ldc
	ln -s /usr/bin/ldmd2 /usr/bin/dmd
fi
