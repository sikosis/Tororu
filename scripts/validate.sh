#!/bin/sh

set -eu

fail() {
	printf 'validate: %s\n' "$1" >&2
	exit 1
}

grep -q '^NAME= Tororu$' src/Makefile || fail 'binary name is not Tororu'
grep -q '^APP_MIME_SIG= application/x-vnd.sikosis-Tororu$' src/Makefile \
	|| fail 'build MIME signature is incorrect'
grep -q '^COMPILER_FLAGS =$' src/Makefile \
	|| fail 'shared compiler flags may affect resource preprocessing'
grep -q 'APP_SIGNATURE = "application/x-vnd.sikosis-Tororu"' src/Constants.h \
	|| fail 'runtime MIME signature is incorrect'
grep -q 'resource app_signature "application/x-vnd.sikosis-Tororu"' src/Tororu.rdef \
	|| fail 'resource MIME signature is incorrect'
grep -q 'APP_VERSION = "0.13"' src/Constants.h \
	|| fail 'runtime version is incorrect'
grep -q 'version-v0.13-' README.md || fail 'README version is incorrect'
grep -q 'middle = 1,' src/Tororu.rdef || fail 'resource minor version is incorrect'
grep -q 'minor  = 3,' src/Tororu.rdef || fail 'resource patch version is incorrect'

if grep -R -q 'config/settings/FlyingTroll' src; then
	fail 'active source still uses the FlyingTroll settings directory'
fi

if grep -q 'system(' src/*.cpp; then
	fail 'active source invokes a shell command'
fi

test -f src/images/button_home || fail 'toolbar image assets are missing'

if grep -q 'GetBitmapFile' src/*.cpp; then
	fail 'bitmap loading is still tied to the working directory'
fi

resource_count=$(grep -c '^resource(1[0-1][0-9], "images/' src/Tororu.rdef)
test "$resource_count" -eq 16 || fail 'not all built-in images are embedded'

printf 'Tororu repository validation passed.\n'
