#!/bin/sh
set -e

if [ "${1#-}" != "$1" ]; then
	set -- dmd "$@"
fi

exec "$@"
