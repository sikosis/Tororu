# Changelog

## v0.2

- Bounded table counts, nesting, rows, columns, cells, and spans so malformed
  or oversized tables cannot index outside renderer storage.
- Made lexer insertion atomic so its count never advances without a valid
  lexeme.
- Released table cells when a document is replaced instead of leaking each
  parsed table tree.
- Initialised and released table and lexeme collections across the full view
  lifecycle.
- Added a regression fixture for oversized and deeply nested tables.

## v0.19

- Bounded HTML tag attribute parsing to prevent memory corruption when modern
  markup or script text contains more tokens than the legacy renderer retains.
- Added a regression fixture covering tags and tag-like script spans with more
  than 20 attributes.

## v0.18

- Added a high-resolution Tororu icon with Haiku-native window styling.
- Embedded a scalable HVIF application icon for Tracker and Deskbar.

## v0.17

- Reduced the default Tororu window size to 640 by 480 pixels.

## v0.16

- Renamed File > Close to File > Quit and made it terminate the application.
- Removed the obsolete demo window from the active Tororu build.
- Added a top-level Gengo menu with six built-in help pages derived from the
  draft Gengo specification.

## v0.15

- Documented the long-term goal of developing Tororu into a lightweight,
  Haiku-native HTML application framework.
- Added a graphical development tracker and detailed milestones covering
  renderer stabilisation, `libtororu`, the C++ host API, actions, CSS, an
  example application, and future Gengo integration.

## v0.14

- Corrected embedded images to use Haiku's translator-bitmap resource type,
  restoring the toolbar buttons and built-in page artwork.

## v0.13

- Embedded toolbar images and built-in page artwork in the application.
- Made bitmap loading fall back to named application resources so Tororu can
  launch correctly from any working directory.

## v0.12

- Removed the redundant C++ language flag from the shared Haiku compiler
  options so resource preprocessing no longer emits a C compiler warning.

## v0.11

- Established the active Tororu source tree from the preserved FlyingTroll
  snapshot.
- Renamed the application binary, signature, menus, built-in pages, and
  settings directory to Tororu.
- Replaced shell-based bookmark-folder launching with the Haiku roster API.
- Added top-level build and validation commands.
