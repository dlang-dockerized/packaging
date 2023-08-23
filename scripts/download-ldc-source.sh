#!/bin/sh
ldcGhRepoUrl="https://github.com/ldc-developers/ldc"
phobosGhRepoUrl="https://github.com/ldc-developers/phobos"
druntimeGhRepoUrl="https://github.com/ldc-developers/druntime"

if [ -z "$DL_LDC_TAG" ]; then
	echo "Error: \$DL_LDC_TAG is not set"
	exit 1
elif [ -z "$LDC_SEMVER_MAJOR" ]; then
	echo "Error: \$LDC_SEMVER_MAJOR is not set"
	exit 1
elif [ -z "$LDC_SEMVER_MINOR" ]; then
	echo "Error: \$LDC_SEMVER_MINOR is not set"
	exit 1
fi

if [ "$LDC_SEMVER_MAJOR" -eq 0 ] || { [ "$LDC_SEMVER_MAJOR" -eq 1 ] && [ "$LDC_SEMVER_MINOR" -le 30 ]; }; then
	needDruntime=1
fi

if [ "$DL_LDC_TAG" = "master" ]; then
	dlLdcUrl="$ldcGhRepoUrl/archive/refs/heads/master.tar.gz"
	dlPhobosUrl="$phobosGhRepoUrl/archive/refs/heads/ldc.tar.gz"
	[ "$needDruntime" ] && dlDruntimeUrl="$druntimeGhRepoUrl/archive/refs/heads/ldc.tar.gz"
elif [ "$DL_LDC_TAG" = "ltsmaster" ]; then
	dlLdcUrl="$ldcGhRepoUrl/archive/refs/heads/ltsmaster.tar.gz"
	dlPhobosUrl="$phobosGhRepoUrl/archive/refs/heads/ldc-ltsmaster.tar.gz"
	[ "$needDruntime" ] && dlDruntimeUrl="$druntimeGhRepoUrl/archive/refs/heads/ldc-ltsmaster.tar.gz"
else
	dlLdcUrl="$ldcGhRepoUrl/archive/refs/tags/$DL_LDC_TAG.tar.gz"
	dlPhobosUrl="$phobosGhRepoUrl/archive/refs/tags/ldc-$DL_LDC_TAG.tar.gz"
	[ "$needDruntime" ] && dlDruntimeUrl="$druntimeGhRepoUrl/archive/refs/tags/ldc-$DL_LDC_TAG.tar.gz"
fi

echo "Downloading $dlLdcUrl"
curl -fLsSo ldc.tar.gz "$dlLdcUrl"

echo "Downloading $dlPhobosUrl"
curl -fLsSo phobos.tar.gz "$dlPhobosUrl"

if [ "$needDruntime" ]; then
	echo "Downloading $dlDruntimeUrl"
	curl -fLsSo druntime.tar.gz "$dlDruntimeUrl"
fi
