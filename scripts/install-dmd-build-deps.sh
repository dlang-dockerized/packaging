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
		# Do nothing
		true
elif
	[ "$DISTRO" = "rhel" ]
	then
		dnf -y update
		dnf -y install \
			gcc \
			curl-minimal \
			gzip \
			tar \
			xz
fi
