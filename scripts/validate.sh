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
grep -q 'APP_VERSION = "0.16"' src/Constants.h \
	|| fail 'runtime version is incorrect'
grep -q 'version-v0.16-' README.md || fail 'README version is incorrect'
grep -q 'middle = 1,' src/Tororu.rdef || fail 'resource minor version is incorrect'
grep -q 'minor  = 6,' src/Tororu.rdef || fail 'resource patch version is incorrect'

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

bitmap_resource_count=$(grep -c "#'bits' import \"images/" src/Tororu.rdef)
test "$bitmap_resource_count" -eq 16 \
	|| fail 'built-in images do not use the translator-bitmap resource type'

grep -q 'new BMenuItem("Quit", new BMessage(FILE_QUIT)' src/OakWindow.cpp \
	|| fail 'File menu does not contain Quit'
grep -q 'new BMenu("Gengo")' src/OakWindow.cpp \
	|| fail 'Gengo menu is missing'
gengo_help_count=$(grep -c 'AddGengoHelpItem(menuGengo' src/OakWindow.cpp)
test "$gengo_help_count" -eq 6 || fail 'Gengo menu does not contain six help pages'

if grep -q 'Some demo\|FILE_DEMO\|OakDemoWindow' src/Makefile src/*.cpp src/*.h; then
	fail 'obsolete demo code remains in the active build'
fi

printf 'Tororu repository validation passed.\n'
