#!/bin/sh
dmdGhRepoUrl="https://github.com/dlang/dmd"
phobosGhRepoUrl="https://github.com/dlang/phobos"

if [ -z "$DL_DMD_TAG" ]; then
	echo "Error: \$DL_DMD_TAG is not set"
	exit 1
fi

if [ "$DL_DMD_TAG" = "master" ]; then
	dlDmdUrl="$dmdGhRepoUrl/archive/refs/heads/master.tar.gz"
	dlPhobosUrl="$phobosGhRepoUrl/archive/refs/heads/master.tar.gz"
elif [ "$DL_DMD_TAG" = "stable" ]; then
	dlDmdUrl="$dmdGhRepoUrl/archive/refs/heads/stable.tar.gz"
	dlPhobosUrl="$phobosGhRepoUrl/archive/refs/heads/stable.tar.gz"
else
	dlDmdUrl="$dmdGhRepoUrl/archive/refs/tags/$DL_DMD_TAG.tar.gz"
	dlPhobosUrl="$phobosGhRepoUrl/archive/refs/tags/$DL_DMD_TAG.tar.gz"
fi

echo "Downloading $dlDmdUrl"
curl -fLsSo dmd.tar.gz "$dlDmdUrl"

echo "Downloading $dlPhobosUrl"
curl -fLsSo phobos.tar.gz "$dlPhobosUrl"
