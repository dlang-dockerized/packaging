#!/bin/sh
set -e
if [ -z "$1" ]; then
	echo "No LDC version provided."
	echo "Usage:  ${0} <version>"
	exit 1
fi

echo "v${1} - LDC"

curl -LSsf \
	"https://github.com/ldc-developers/ldc/raw/v${1}/packaging/dub_version"
echo ' - DUB'
