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
grep -q 'APP_VERSION = "0.31"' src/Constants.h \
	|| fail 'runtime version is incorrect'
grep -q 'version-v0.31-' README.md || fail 'README version is incorrect'
grep -q 'middle = 3,' src/Tororu.rdef || fail 'resource minor version is incorrect'
grep -q 'minor  = 1,' src/Tororu.rdef || fail 'resource patch version is incorrect'
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
test -f tests/fixtures/image-limits.html \
	|| fail 'image limits regression fixture is missing'
test -f tests/fixtures/heading-limits.html \
	|| fail 'heading limits regression fixture is missing'
grep -q 'renderer-smoke.html' tests/fixtures/index.html \
	|| fail 'renderer fixture is not linked from the test index'
grep -q 'many-attributes.html' tests/fixtures/index.html \
	|| fail 'attribute bounds fixture is not linked from the test index'
grep -q 'table-limits.html' tests/fixtures/index.html \
	|| fail 'table limits fixture is not linked from the test index'
grep -q 'empty.html' tests/fixtures/index.html \
	|| fail 'empty-file fixture is not linked from the test index'
grep -q 'image-limits.html' tests/fixtures/index.html \
	|| fail 'image limits fixture is not linked from the test index'
grep -q 'heading-limits.html' tests/fixtures/index.html \
	|| fail 'heading limits fixture is not linked from the test index'
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
grep -q 'AdvanceLine(n_lines)' src/OakView.cpp \
	|| fail 'line-cache insertion is not bounded'
if grep -q '^[[:space:]]*n_lines++;\|^[[:space:]]*line_pos++;' src/OakView.cpp; then
	fail 'line-cache cursor advances without a bounds check'
fi
grep -q 'n_images < MAX_IMAGES' src/OakView.cpp \
	|| fail 'image storage is not bounded'
image_count=$(grep -o '<img ' tests/fixtures/image-limits.html | wc -l | tr -d ' ')
test "$image_count" -gt 255 \
	|| fail 'image limits fixture does not exceed renderer storage'
grep -q 'PushHeadingFont' src/OakView.cpp \
	|| fail 'heading font storage is not bounded'
heading_count=$(grep -o '<h[1-4]>' tests/fixtures/heading-limits.html | wc -l | tr -d ' ')
test "$heading_count" -gt 10 \
	|| fail 'heading limits fixture does not exceed renderer storage'

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
grep -q 'menuDebug->AddSeparatorItem()' src/OakWindow.cpp \
	|| fail 'Debug test fixtures are not separated from controls'
debug_fixture_count=$(grep -c 'AddDebugFixtureItem(menuDebug' src/OakWindow.cpp)
test "$debug_fixture_count" -eq 6 \
	|| fail 'Debug menu does not contain every renderer fixture'
html_resource_count=$(grep -c "#'HTML' import \"../tests/fixtures/" src/Tororu.rdef)
test "$html_resource_count" -eq 5 \
	|| fail 'non-empty renderer fixtures are not embedded'
grep -q 'fixture.ReplaceAll("../../src/images/haikulogo", "images/haikulogo")' \
	src/OakWindow.cpp \
	|| fail 'embedded fixture images do not resolve through application resources'
grep -q 'font size="+5" color="#ffff00"' tests/fixtures/renderer-smoke.html \
	|| fail 'renderer smoke fixture does not make enlarged text obvious'
grep -q 'Yellow underlined link' tests/fixtures/renderer-smoke.html \
	|| fail 'renderer smoke fixture does not identify link styling'
grep -q 'ScrollToAnchor(anchor.String())' src/OakView.cpp \
	|| fail 'fragment-only links do not scroll the current document'
grep -q 'BRect bvr = Bounds()' src/OakView.cpp \
	|| fail 'renderer cache does not follow the view bounds'
grep -q 'SetViewColor(bgcolor)' src/OakView.cpp \
	|| fail 'native view background does not match the document'
if grep -q 'font.Spacing() == be_fixed_font->Spacing()' src/OakView.cpp; then
	fail 'explicit font sizes are still reset by font spacing'
fi
grep -q "href\[0\] == '#'" src/OakView.cpp \
	|| fail 'fragment clicks are not routed directly to document anchors'
grep -q 'SetHeadingStyle' src/OakView.cpp \
	|| fail 'heading fonts do not apply a distinct style'
grep -q 'face |= B_BOLD_FACE' src/OakView.cpp \
	|| fail 'heading fonts are not bold'
grep -q 'ScrollTo(BPoint(0, position))' src/OakView.cpp \
	|| fail 'anchor navigation does not scroll the target view directly'
grep -q 'p == OAK_REDRAW && n_anchors < MAX_ANCHORS' src/OakView.cpp \
	|| fail 'anchors are collected outside the final layout pass'
grep -q 'ActivateLink(href)' src/OakView.cpp \
	|| fail 'fragment links are not activated on mouse-down'
grep -q 'OAK_SCROLL_TO_ANCHOR' src/OakView.cpp \
	|| fail 'fragment scrolling is not deferred through the view looper'
grep -q 'linkBounds.InsetBy(-2, -3)' src/OakView.cpp \
	|| fail 'text links do not have a practical hit area'
for level in 1 2 3 4; do
	grep -q "<h$level>Heading $level sample</h$level>" \
		tests/fixtures/heading-limits.html \
		|| fail "heading limits fixture does not demonstrate H$level"
done

if grep -q 'Some demo\|FILE_DEMO\|OakDemoWindow' src/Makefile src/*.cpp src/*.h; then
	fail 'obsolete demo code remains in the active build'
fi

printf 'Tororu repository validation passed.\n'
