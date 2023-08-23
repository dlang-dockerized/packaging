#!/bin/sh
set -e

if [ -z $DMD ]; then
    echo "\$DMD is not set, detecting compiler"
    for compiler in dmd ldmd2 gdmd; do
        if [ $(command -v $compiler) ]; then
            DMD=$compiler
            break
        fi
    done
	echo "Error: Unable to detect a compiler"
	exit 1
fi
echo "Compiler is $DMD"

# Unpack sources
mkdir -p dub
tar -xf dub.tar.gz -C dub --strip-components=1

# Build
cd dub
echo "Building DUB"
DFLAGS="-O -inline" $DMD -run build.d
cd ..
