#!/bin/sh
set -e
if [ -z "$1" ]; then
	echo "No DMD version provided."
	echo "Usage:  ${0} <version>"
	exit 1
fi

echo "DMD version ${1}"

# Create temporary directory.
tmpDir=$(mktemp -d)

# Download + unpack.
curl -Ssf \
	-o "${tmpDir}/dmd.tar.xz" \
	"https://download.dlang.org/releases/2.x/${1}/dmd.${1}.linux.tar.xz"
tar -C $tmpDir \
	-xf "${tmpDir}/dmd.tar.xz"

# Query DUB for its version.
${tmpDir}/dmd2/linux/bin64/dub --version

# Cleanup.
rm -rf $tmpDir
