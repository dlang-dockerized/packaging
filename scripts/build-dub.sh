#!/bin/sh
set -e

# unpack
mkdir -p dub
tar -xf dub.tar.gz -C dub --strip-components=1

# build
cd dub
dmd -run build.d
cd ..
