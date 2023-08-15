#!/bin/sh
set -e

# unpack
mkdir -p dmd
mkdir -p phobos
tar -xf dmd.tar.gz -C dmd --strip-components=1
tar -xf phobos.tar.gz -C phobos --strip-components=1

# build
if [ -f "dmd/compiler/src/build.d" ]; then
	buildDpath="dmd/compiler/src/build.d"
elif [ -f "dmd/src/build.d" ]; then
	buildDpath="dmd/src/build.d"
else
	echo "Unsupported DMD source version"
	exit 1
fi

export INSTALL=/opt/dmd
export INSTALL_DIR=$INSTALL

echo "Building DMD"
make -C dmd -f posix.mak all
rm /usr/bin/dmd
ln -s /opt/build/dmd/generated/linux/release/64/dmd /usr/bin/dmd

echo "Building Phobos"
make -C phobos -f posix.mak
