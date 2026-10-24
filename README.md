<h1 align="center">Tororu</h1>

<p align="center">
  <img src="https://img.shields.io/badge/version-v0.13-f5a623" alt="Version v0.13">
  <img src="https://img.shields.io/badge/platform-Haiku-ffcc00" alt="Platform: Haiku">
  <img src="https://img.shields.io/badge/C%2B%2B-17-00599c" alt="C++17">
</p>

Tororu is a lightweight local-documentation browser for Haiku. It continues
the original FlyingTroll project and its small, native HTML layout engine. The
browser intentionally has no JavaScript, CSS, or network support: its focus is
fast browsing of documentation and other local HTML files.

![The original FlyingTroll interface](FlyingTroll-Original/FlyingTroll.png)

## Current status

Version v0.13 establishes the Tororu source tree from the preserved
FlyingTroll code, with Tororu application metadata and a separate Tororu
settings directory. The original source remains unchanged under
`FlyingTroll-Original/` for comparison and attribution.

Tororu currently supports:

- local HTML and plain-text files;
- back and forward history;
- bookmarks stored in `~/config/settings/Tororu/Bookmarks`;
- in-page text search;
- basic HTML text, links, images, tables, and character-set conversion.

## Building on Haiku

Tororu uses Haiku's standard `makefile-engine` and requires a C++17-capable
Haiku development environment.

```sh
make
```

Toolbar images and built-in page artwork are embedded in the application, so
the resulting executable can be launched from any working directory.

To run the repository's platform-independent consistency checks:

```sh
make validate
```

## Source layout

- `src/` — active Tororu source and build definition.
- `FlyingTroll-Original/` — untouched upstream snapshot.
- `scripts/validate.sh` — metadata and repository consistency checks.

## Heritage

FlyingTroll was written by Makitka in 2007 and described upstream as BSD/MIT
licensed. Tororu preserves that implementation while bringing it forward for
current Haiku systems.

