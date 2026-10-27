#!/bin/sh

set -eu

if [ "$#" -ne 1 ]; then
	printf 'Usage: %s /path/to/Tororu\n' "$0" >&2
	exit 2
fi

tororu_binary=$1
script_directory=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
repository_directory=$(dirname -- "$script_directory")
fixture="$repository_directory/tests/fixtures/index.html"

if [ ! -x "$tororu_binary" ]; then
	printf 'render-smoke: Tororu executable not found: %s\n' "$tororu_binary" >&2
	exit 1
fi

printf 'Opening the Tororu renderer test suite.\n'
printf 'Follow the pass criteria shown on the index page.\n'
"$tororu_binary" "$fixture"
