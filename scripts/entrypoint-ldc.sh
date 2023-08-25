#!/bin/sh
set -e

export PATH="/opt/ldc/bin:$PATH"

if [ "$(ulimit -n)" -gt 5120 ]; then
	ulimit -n 5120 || true
fi

if [ "${1#-}" != "$1" ]; then
	set -- ldc2 "$@"
fi

exec "$@"
