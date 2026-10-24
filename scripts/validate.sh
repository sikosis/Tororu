#!/bin/sh

set -eu

fail() {
	printf 'validate: %s\n' "$1" >&2
	exit 1
}

grep -q '^NAME= Tororu$' src/Makefile || fail 'binary name is not Tororu'
grep -q '^APP_MIME_SIG= application/x-vnd.sikosis-Tororu$' src/Makefile \
	|| fail 'build MIME signature is incorrect'
grep -q 'APP_SIGNATURE = "application/x-vnd.sikosis-Tororu"' src/Constants.h \
	|| fail 'runtime MIME signature is incorrect'
grep -q 'resource app_signature "application/x-vnd.sikosis-Tororu"' src/Tororu.rdef \
	|| fail 'resource MIME signature is incorrect'
grep -q 'APP_VERSION = "0.11"' src/Constants.h \
	|| fail 'runtime version is incorrect'
grep -q 'version-v0.11-' README.md || fail 'README version is incorrect'
grep -q 'middle = 1,' src/Tororu.rdef || fail 'resource minor version is incorrect'
grep -q 'minor  = 1,' src/Tororu.rdef || fail 'resource patch version is incorrect'

if grep -R -q 'config/settings/FlyingTroll' src; then
	fail 'active source still uses the FlyingTroll settings directory'
fi

if grep -q 'system(' src/*.cpp; then
	fail 'active source invokes a shell command'
fi

test -f src/images/button_home || fail 'toolbar image assets are missing'

printf 'Tororu repository validation passed.\n'
