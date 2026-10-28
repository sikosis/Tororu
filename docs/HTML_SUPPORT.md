# Tororu HTML support

This document records the behaviour implemented by the current FlyingTroll
renderer in Tororu. It is a compatibility baseline, not a promise of complete
HTML conformance. The renderer is intentionally small and targets local
documents and future bundled application interfaces.

## Documents and navigation

- Local HTML and plain-text files can be opened directly.
- Local image files are wrapped in a generated HTML document.
- Relative file and image paths resolve from the current document directory.
- Links support local paths and document fragments. `http://` targets are
  recognised syntactically but cannot currently be retrieved.
- Named anchors use `<a name="…">`; fragment links use `href="#…"`.
- Built-in pages use the `about:` scheme.
- Bookmarks using Haiku's bookmark MIME type are supported.

`https://` retrieval is not implemented. Tororu currently runs local HTML
interfaces and is not a general-purpose web client.

## Supported elements

| Area | Elements and behaviour |
| --- | --- |
| Document | `html`, `head`, `title`, `body` |
| Text | `b`, `i`, `u`, `font`, `tt`, `sup`, `pre` |
| Blocks | `p`, `br`, `hr`, `center`, `blockquote` |
| Headings | `h1`, `h2`, `h3`, `h4` |
| Lists | `ul`, `li` |
| Navigation | `a` with `href` or `name` |
| Media | `img`, including local and embedded bitmap resources |
| Tables | `table`, `tr`, `td` |
| Legacy layout | `spacer` and the internal `ft:pre_tab` element |

Element matching is case-insensitive. Unknown elements are generally ignored,
but malformed markup may still expose parser limitations.

## Supported attributes

- `body`: `background`, `bgcolor`, `text`, `link`
- `font`: `size`, `color`, `face`
- `a`: `href`, `name`
- `img`: `src`, `width`, `height`, `align`, `alt`, `border`
- `table`: `width`, `border`, `cellpadding`, `bgcolor`
- `td`: `width`, `colspan`, `rowspan`, `align`, `bgcolor`
- `hr`: `color`
- `spacer`: `width`

Widths may be expressed as pixels or percentages where the implementation
checks for them. Colours accept six-digit hexadecimal values and the named
colours `white`, `red`, `green`, `gray`, `yellow`, and `blue`.

## Character sets

The View menu exposes automatic conversion, ISO-8859-1, Windows-1252, KOI8-R,
DOS CP866, and UTF-8. Input is converted to UTF-8 before layout.

## Intentionally unsupported

- CSS stylesheets, selectors, and the CSS box model
- JavaScript or another executable `<script>` language
- iframe contents
- forms and form controls
- audio, video, canvas, SVG, and modern semantic elements
- HTTPS and a production network stack
- standards-compatible DOM behaviour

`script` and `iframe` blocks are skipped rather than executed or embedded.
Gengo and the planned DOM-lite API are future framework stages and are not part
of the current HTML renderer.

## Smoke fixture

After building Tororu on Haiku, run:

```sh
make smoke TORORU=/path/to/Tororu
```

The runner opens `tests/fixtures/index.html`, which links to the representative
renderer fixture and lists the pass criteria. The suite does not depend on
network access. Missing labels, overlapping table cells, broken navigation, or
a missing Haiku image indicate a renderer regression.

This is currently a repeatable manual visual test. Automated pixel comparison
will require a Haiku-native capture harness and stable font and appearance
settings.

The suite also includes `many-attributes.html`, which protects the parser
against modern markup and script text containing more attribute-like tokens
than Tororu retains. Extra attributes are deliberately ignored after the
bounded parser storage is full.

`table-limits.html` covers oversized row and column spans, excess cells and
table nesting deeper than the renderer retains. Excess structure is ignored;
content may be simplified, but it must not access memory outside the bounded
table storage.

`empty.html` verifies that a zero-byte document loads as an empty page without
closing Tororu. Source documents larger than 16 MiB are rejected before the
renderer allocates its parsing buffers.

`image-limits.html` contains more image elements than the renderer retains.
Tororu loads the first 255 valid images and safely ignores the remainder.
The layout cache retains 30,000 line entries; longer documents safely reuse
the final entry instead of extending the fixed cache.
