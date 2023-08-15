#!/bin/sh
if [ -z "$DL_DUB_TAG" ]; then
	echo "No \$DL_DUB_TAG"
	exit 1
else
	if [ "$DL_DUB_TAG" = "stable" ]; then
		DL_DUB_URL="https://github.com/dlang/dub/archive/refs/heads/stable.tar.gz"
	else
		DL_DUB_URL="https://github.com/dlang/dub/archive/refs/tags/$DL_DUB_TAG.tar.gz"
	fi
fi

echo "Downloading $DL_DUB_URL"
curl -fLsSo dub.tar.gz "$DL_DUB_URL"
