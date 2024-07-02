#!/bin/sh
if [ -z "$DL_PREBUILT_LDC_RELEASE" ]; then
	DL_PREBUILT_LDC_RELEASE="1.20.1"
fi

dlPrebuiltLdcUrl="https://github.com/ldc-developers/ldc/releases/download/v${DL_PREBUILT_LDC_RELEASE}/ldc2-${DL_PREBUILT_LDC_RELEASE}-linux-x86_64.tar.xz"

cd /opt/

echo "Downloading $dlPrebuiltLdcUrl"
curl -fLsSo prebuilt-ldc.tar.xz "$dlPrebuiltLdcUrl"

echo "Unpacking"
mkdir prebuilt-ldc
tar -xf prebuilt-ldc.tar.xz -C prebuilt-ldc --strip-components=1

echo "Symlinking DMD to pre-built LDMD2"
ln -s /opt/prebuilt-ldc/bin/ldmd2 /usr/bin/dmd
