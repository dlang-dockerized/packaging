#!/bin/sh
set -e

# Paths
cfDir='./containerfiles'
cfRepo='https://github.com/dlang-dockerized/containerfiles.git'

# Check whether ddct is available as expected.
if ! command -v ./ddct >/dev/null; then
	echo '`ddct` is not available.'
	echo 'Please run this script from the root directory of dlang-dockerized.'
	exit 1
fi

# Do not overwrite user data.
if [ -d "$cfDir" ]; then
	echo "Containerfiles directory \`$cfDir\` already exists."
	exit 1
fi

# Clone "containerfiles" repo.
git clone --depth=1 --branch=dlang-rox "$cfRepo" "$cfDir"

# Build Containerfiles.
./ddct generate-all

# Commit changes.
cd "$cfDir"
git add -A
git commit -m "Update containerfiles"
git push
cd ..
