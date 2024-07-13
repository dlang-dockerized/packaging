#!/bin/sh
if git -C ./containerfiles diff --quiet; then
	echo "Up-to-date."
	exit 0
fi
set -e
git -C ./containerfiles add -A
git -C ./containerfiles commit -m "Update containerfiles to dlang-dockerized/packaging@${GITHUB_SHA}"
git -C ./containerfiles push
