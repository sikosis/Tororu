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
grep -q 'APP_VERSION = "0.23"' src/Constants.h \
	|| fail 'runtime version is incorrect'
grep -q 'version-v0.23-' README.md || fail 'README version is incorrect'
grep -q 'middle = 2,' src/Tororu.rdef || fail 'resource minor version is incorrect'
grep -q 'minor  = 3,' src/Tororu.rdef || fail 'resource patch version is incorrect'
grep -q 'BRect r(100, 100, 740, 580);' src/Oak.cpp \
	|| fail 'default window size is incorrect'
grep -q '^resource vector_icon {' src/Tororu.rdef \
	|| fail 'native application icon is missing'
test -f artwork/TororuIcon.png || fail 'high-resolution icon source is missing'
test -f artwork/TororuIcon.hvif || fail 'native HVIF icon is missing'
test -f docs/HTML_SUPPORT.md || fail 'HTML compatibility baseline is missing'
test -x scripts/render-smoke.sh || fail 'renderer smoke runner is not executable'
test -f tests/fixtures/index.html || fail 'renderer fixture index is missing'
test -f tests/fixtures/renderer-smoke.html || fail 'renderer smoke fixture is missing'
test -f tests/fixtures/many-attributes.html \
	|| fail 'attribute bounds regression fixture is missing'
test -f tests/fixtures/table-limits.html \
	|| fail 'table limits regression fixture is missing'
test -f tests/fixtures/empty.html \
	|| fail 'empty-file regression fixture is missing'
test ! -s tests/fixtures/empty.html \
	|| fail 'empty-file regression fixture is not empty'
grep -q 'renderer-smoke.html' tests/fixtures/index.html \
	|| fail 'renderer fixture is not linked from the test index'
grep -q 'many-attributes.html' tests/fixtures/index.html \
	|| fail 'attribute bounds fixture is not linked from the test index'
grep -q 'table-limits.html' tests/fixtures/index.html \
	|| fail 'table limits fixture is not linked from the test index'
grep -q 'empty.html' tests/fixtures/index.html \
	|| fail 'empty-file fixture is not linked from the test index'
grep -q '^smoke:' Makefile || fail 'smoke test Make target is missing'
grep -q 'MAX_TAG_ATTRIBUTES' src/OakView.cpp \
	|| fail 'tag parser is not bounded by the attribute limit'
grep -q 'i < capacity' src/OakView.cpp \
	|| fail 'tag parser does not stop at its supplied capacity'
attribute_count=$(grep -o 'data-[0-9][0-9]=' tests/fixtures/many-attributes.html | wc -l | tr -d ' ')
test "$attribute_count" -eq 25 \
	|| fail 'attribute bounds fixture does not exceed the parser capacity'
table_depth_count=$(grep -o '<table' tests/fixtures/table-limits.html | wc -l | tr -d ' ')
test "$table_depth_count" -gt 20 \
	|| fail 'table limits fixture does not exceed the nesting limit'
grep -q 'MAX_TABLE_CELLS' src/OakView.cpp \
	|| fail 'table cell storage is not bounded'
grep -q 'MAX_TABLE_DEPTH' src/OakView.cpp \
	|| fail 'table nesting is not bounded'
if grep -q '^[[:space:]]*n_lexems++;' src/OakView.cpp; then
	fail 'lexeme count advances separately from insertion'
fi
grep -q 'n_tables = 0;' src/OakView.cpp \
	|| fail 'table collection is not initialised'
grep -q 'n_lexems = 0;' src/OakView.cpp \
	|| fail 'lexeme collection is not initialised'
grep -q 'MAX_DOCUMENT_BYTES' src/OakView.cpp \
	|| fail 'document input is not bounded'
grep -q 'text.SetTo(input, inputLength)' src/OakView.cpp \
	|| fail 'document input is not copied with an explicit length'

for element in h1 h2 p b i u tt sup font blockquote pre ul li a table tr td img hr; do
	grep -qi "<$element" tests/fixtures/renderer-smoke.html \
		|| fail "renderer smoke fixture does not cover <$element>"
done

if grep -q 'config/settings/FlyingTroll' src/*.cpp src/*.h; then
	fail 'active source still uses the FlyingTroll settings directory'
fi

if grep -i -q 'documentation browser\|local-documentation' \
	README.md GENGO.md docs/*.md src/*.cpp src/*.h; then
	fail 'Tororu is still described as a documentation browser'
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
