# Changelog

## v0.31

- Deferred fragment scrolling through the view's looper so pointer-event
  processing cannot overwrite the new scroll position.
- Ensured in-memory pages build interactive link regions and expanded text-link
  hit areas slightly around their rendered bounds.
- Flushed link and anchor diagnostics immediately, including the resolved
  anchor position and document height.

## v0.3

- Activated fragment links on primary mouse-down so minor pointer movement
  before mouse-up cannot suppress in-document navigation.
- Recorded named anchors only during the final redraw, avoiding duplicate
  positions collected during measurement passes.
- Forced the window to update after applying an anchor scroll position.

## v0.29

- Rendered H1 through H4 with bold heading faces as well as distinct sizes.
- Restored the complete saved font face when a heading closes.
- Applied anchor positions directly to both the vertical scrollbar and target
  view after updating the scroll range.
- Separated normal heading samples from malformed nesting in the Debug fixture.

## v0.28

- Preserved explicit HTML font sizes instead of replacing sized fonts through
  a legacy fixed-spacing heuristic before drawing.
- Routed fragment link clicks directly to the current document's anchor map.

## v0.27

- Made fragment-only links scroll the current in-memory page instead of trying
  to reopen its Debug address as a file.
- Rebuilt the renderer cache from the actual view bounds after resize and kept
  the native view background synchronised with the document background colour.
- Strengthened the smoke fixture's font, link and resize checks.

## v0.26

- Added all renderer regression fixtures to the Debug menu below a separator.
- Embedded non-empty test pages in the application so Debug tests work from
  any launch directory.
- Made in-memory test pages update the window title, address and scroll bars.

## v0.25

- Bounded nested heading state to ten saved fonts so malformed heading markup
  cannot write beyond the renderer's font stack.
- Safely ignored additional heading levels until their matching closing tags.
- Added a regression fixture for excessive mixed heading nesting.

## v0.24

- Bounded line-cache cursors so documents exceeding 30,000 layout lines reuse
  the final cache entry instead of indexing beyond fixed renderer storage.
- Bounded decoded images to the 255 entries retained by the renderer.
- Added an image-limit regression fixture containing more than 255 valid image
  elements.

## v0.23

- Restricted terminology validation to source and documentation files so stale
  Haiku build objects cannot cause false failures.

## v0.22

- Positioned Tororu consistently as a Haiku-native HTML application framework
  and retired its earlier document-oriented label.
- Renamed the current executable to the reference application in project
  documentation, distinguishing it from the reusable `libtororu` engine.
- Updated the built-in home page to reflect the framework identity.

## v0.21

- Made text-file reads length-aware so input does not need an accidental null
  terminator beyond the file contents.
- Handled empty files, short reads, allocation failures, and character-set
  conversion failures without replacing the current document.
- Limited source documents to 16 MiB before allocating renderer buffers.
- Added an empty-file regression fixture to the manual renderer suite.

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
