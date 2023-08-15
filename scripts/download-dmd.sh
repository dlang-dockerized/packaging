#!/bin/sh
if [ -z "$DL_DMD_TAG" ]; then
	echo "No \$DL_DMD_TAG"
	exit 1
else
	if [ "$DL_DMD_TAG" = "master" ]; then
		dlDmdUrl="https://github.com/dlang/dmd/archive/refs/heads/master.tar.gz"
		dlPhobosUrl="https://github.com/dlang/phobos/archive/refs/heads/master.tar.gz"
	elif [ "$DL_DMD_TAG" = "stable" ]; then
		dlDmdUrl="https://github.com/dlang/dmd/archive/refs/heads/stable.tar.gz"
		dlPhobosUrl="https://github.com/dlang/phobos/archive/refs/heads/stable.tar.gz"
	else
		dlDmdUrl="https://github.com/dlang/dmd/archive/refs/tags/$DL_DMD_TAG.tar.gz"
		dlPhobosUrl="https://github.com/dlang/phobos/archive/refs/tags/$DL_DMD_TAG.tar.gz"
	fi
fi

echo "Downloading $dlDmdUrl"
curl -fLsSo dmd.tar.gz "$dlDmdUrl"

echo "Downloading $dlPhobosUrl"
curl -fLsSo phobos.tar.gz "$dlPhobosUrl"
