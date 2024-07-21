#!/bin/sh
noUntracked() {
	return $(git -C ~/containerfiles ls-files --other --directory --exclude-standard | sed q | wc -l)
}
if git -C ~/containerfiles diff --quiet && noUntracked; then
	echo "Up-to-date."
	exit 0
fi
set -e
git -C ~/containerfiles add -A
git -C ~/containerfiles commit -m "Update containerfiles to dlang-dockerized/packaging@${GITHUB_SHA}"
git -C ~/containerfiles push
