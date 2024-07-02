#!/bin/sh
dubGhRepoUrl="https://github.com/dlang/dub"

if [ -z "$DL_DUB_TAG" ]; then
	echo "Error: \$DL_DUB_TAG is not set"
	exit 1
fi

if [ "$DL_DUB_TAG" = "stable" ]; then
	DL_DUB_URL="$dubGhRepoUrl/archive/refs/heads/stable.tar.gz"
else
	DL_DUB_URL="$dubGhRepoUrl/archive/refs/tags/$DL_DUB_TAG.tar.gz"
fi

echo "Downloading $DL_DUB_URL"
curl -fLsSo dub.tar.gz "$DL_DUB_URL"
