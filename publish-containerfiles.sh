#!/bin/sh

# Paths
cfDir='./containerfiles'
cfRepo='https://github.com/dlang-dockerized/containerfiles.git'

# Do not overwrite user data.
if [ -d "$cfDir" ]; then
	echo "Containerfiles directory \`$cfDir\` already exists."
	exit 1
fi

# Clone "containerfiles" repo
git clone "$cfRepo" "$cfDir"

# Build Containerfiles
./ddct generate-all

# Commit changes
cd "$cfDir"
git add -A
git commit -m "Update containerfiles"
git push
cd ..
