# Changelog

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
