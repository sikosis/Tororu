# Gengo (言語)

**Gengo** is the scripting language for [Tororu](https://github.com/sikosis/Tororu), the lightweight Haiku-native HTML application framework. It plays the role JavaScript plays in Electron, but at a fraction of the size and with Haiku's own idioms (BMessages, BFS attributes, the scripting suites, the roster) as first-class features instead of bolt-ons.

*Gengo* is Japanese for "language", in keeping with Tororu ("troll") and FlyingTroll heritage.

| | |
|---|---|
| Document status | Draft design, v0.1 |
| Date | 24 October 2026 |
| Target host | Tororu (libtororu), Haiku R1/beta5 and later |
| Implementation language | C++17, no third-party dependencies |
| File extension | `.gengo` |
| MIME type | `text/x-gengo` |

---

## 1. Context and assumptions

This design is written against what Tororu is **today** and what it is **meant to become**.

**Today (v0.22):** Tororu is an early Haiku-native HTML application framework derived from FlyingTroll (Makitka, 2007). It has its own small HTML layout engine and deliberately has **no JavaScript, no CSS and no network support**. Its reference application handles local HTML and plain text, history, bookmarks, in-page search, and basic text, links, images and tables.

**Goal:** a lightweight, Haiku-native HTML application framework built around `libtororu`, native C++, BMessages and Haiku scripting.

Gengo is the piece that turns Tororu's static markup engine into a scriptable application framework. Because Tororu has no JavaScript engine to replace, Gengo is not constrained by web compatibility. It can be small, safe and Haiku-shaped.

**Assumptions** (to confirm or correct as the source evolves):

1. The layout engine, window and view code live in `src/` and will be factored into `libtororu`; Gengo ships inside that library.
2. Each Tororu window is a `BWindow` with its own looper thread, and a page maps to one window.
3. The HTML engine does not yet have `id`-addressable elements, form controls or a mutation API. Section 12 lists the engine changes Gengo needs.
4. Network access stays out of scope for v0.x, matching Tororu's current stance.

---

## 2. Goals and non-goals

### Goals

- **Small.** Target well under 10k lines of C++, no dependencies, quick to start, low memory per page.
- **Safe by default.** Scripts have no ambient authority. Everything dangerous is a declared capability.
- **Haiku-native.** Maps are BMessages. Four-character codes are literals. Scripting suites, BFS attributes and queries, node monitoring, `BRoster`, `BClipboard` and `BNotification` are built into the standard library.
- **Easy to read.** Someone who knows Lua, Python or JavaScript can read a Gengo file with no tutorial.
- **Easy to embed.** Registering a native function from C++ is a few lines.
- **Friendly errors.** Every error carries file, line and column, and Tororu shows it on a proper error page.

### Non-goals (v0.x)

- JavaScript compatibility, npm, or any package ecosystem.
- Classes, inheritance, prototypes, operator overloading.
- `async`/`await` or promises (see 7 for the event and task model instead).
- Network access, `eval` of arbitrary strings, native extension loading from scripts.
- JIT compilation.

---

## 3. Language overview

A first look:

```gengo
// A counter. Comments are // and /* ... */
let count = 0

fn increment() {
    count += 1
    dom.get("total").text = "Count: {count}"
}

ready(fn() {
    dom.get("plus").on("click", increment)
})
```

### 3.1 Lexical structure

- Source is UTF-8. Identifiers: letters (including non-ASCII), digits and `_`, not starting with a digit.
- Statements end at a newline. Semicolons are allowed but never required. A line continues if it ends with an operator, `,`, `(`, `[` or `{`, or the next line starts with `.`, `and`, `or` or an operator.
- Blocks use braces in K&R style, matching the Tororu codebase.
- Keywords: `let const fn return if else for in while break continue match try catch throw use and or not nil true false`.

### 3.2 Types

| Type | Notes | Literal |
|---|---|---|
| `nil` | absence of a value | `nil` |
| `bool` | | `true`, `false` |
| `int` | 64-bit signed | `42`, `0xFF`, `1_000_000` |
| `num` | 64-bit float | `3.14`, `2e10` |
| `str` | immutable UTF-8 | `"hello"`, `"""multi line"""`, `r"raw\path"` |
| `what` | four-character message code (int32) | `'MSG1'`, `'GENG'` |
| `list` | ordered, growable | `[1, 2, 3]` |
| `map` | ordered string-keyed map, **is a BMessage** | `{ name: "Tororu", v: 1 }` |
| `fn` | first-class closure | `fn(x) { return x * 2 }` |
| `handle` | opaque native object (element, window, file, target) | not constructible |

Notes:

- **Truthiness:** only `nil` and `false` are false. `0`, `""`, `[]` and `{}` are true. This removes a whole class of surprises.
- **`/`** is always float division. Use `math.idiv(a, b)` for integer division, `%` for remainder.
- **`==`** compares scalars by value and `list`/`map` structurally (with cycle protection). `is` tests identity.
- Maps keep **insertion order**, which also makes BMessage round-trips predictable.

### 3.3 Variables and scope

```gengo
let name = "Gengo"        // mutable, block scoped
const VERSION = "v0.1"    // cannot be reassigned
```

Lexical scoping with closures. No implicit globals: assigning to an undeclared name is a compile error. Each page has one global scope, and `use` imports are file local.

### 3.4 Strings

```gengo
let who = "Haiku"
let msg = "Hello, {who}! 1 + 1 = {1 + 1}"   // interpolation with { }
let lit = "A literal brace: \{ and \}"
let page = """
    <h1>{who}</h1>
"""                                          // common indentation is stripped
```

Strings are indexed by Unicode code point, not byte. Slicing: `s[0..3]` (exclusive end) or `s[0..=3]` (inclusive).

### 3.5 Control flow

```gengo
if x > 10 {
    ...
} else if x > 5 {
    ...
} else {
    ...
}

for item in list { ... }
for i in 0..10 { ... }            // 0 to 9
for i in 0..=10 { ... }           // 0 to 10
for key, value in some_map { ... }
while cond { ... }

match event.key {
    "Enter"  { submit() }
    "Escape" { cancel() }
    else     { }
}
```

`match` compares with `==` and has no fall-through. `break` and `continue` work in loops.

### 3.6 Functions

```gengo
fn greet(who, greeting = "Hello") {
    return "{greeting}, {who}!"
}

let double = fn(x) { return x * 2 }
let twice = fn(f, x) { return f(f(x)) }

greet("Tororu")
greet("Tororu", greeting: "Konnichiwa")   // named arguments
```

A function with no `return` returns `nil`. Functions are closures. There is no variadic syntax in v0.1 (pass a list).

### 3.7 Collections

```gengo
let names = ["Ada", "Linus", "Axel"]
names.push("Adrien")
names[-1]                   // last element
names[1..3]                 // slice
names.map(fn(n) { return n.upper() })

let person = { name: "Ada", "home dir": "/boot/home" }
person.name                 // dot access for plain keys
person["home dir"]          // index access for any key
person?.address?.city       // optional chaining, nil if missing
person.age ?? 30            // nil-coalescing
```

Methods are provided by the built-in type tables (`str`, `list`, `map`, `num`). There are no user-defined methods; use maps holding functions when you want an object.

### 3.8 Errors

```gengo
try {
    let text = fs.read("/boot/home/notes.txt")
} catch e {
    dialog.alert("Could not open: {e.message}")
}

throw { code: "E_BAD_INPUT", message: "Name is empty" }
```

Any value can be thrown; errors raised by the runtime are maps with `code`, `message`, `file`, `line`, `col` and (when relevant) `status` carrying the Haiku `status_t`, so `e.status == B_ENTRY_NOT_FOUND` style checks are possible through `sys.errors`.

### 3.9 Modules

```gengo
use fs                       // built-in module
use "lib/format.gengo" as format
```

Built-ins are checked against the app's declared capabilities (section 9). File modules resolve relative to the importing file, must stay inside the app folder, run once and export their top-level `export`ed names:

```gengo
// lib/format.gengo
export fn kilobytes(n) { return "{(n / 1024).round(1)} KB" }
```

---

## 4. Haiku-native features

These are what make Gengo more than "a small Lua".

### 4.1 Maps are BMessages

A Gengo `map` converts to and from `BMessage` with no ceremony. Type mapping:

| Gengo | BMessage field |
|---|---|
| `int` | `B_INT64_TYPE` |
| `num` | `B_DOUBLE_TYPE` |
| `str` | `B_STRING_TYPE` |
| `bool` | `B_BOOL_TYPE` |
| `what` | `B_INT32_TYPE` (keeps 4-char code) |
| `list` | repeated field of the same type |
| `map` | nested `BMessage` (`B_MESSAGE_TYPE`) |
| `nil` | field omitted |

Native code reading messages sent from Gengo gets idiomatic `BMessage`s. Mixed-type lists are an error when converting.

### 4.2 Messaging

```gengo
// Receive
on_message('GENG', fn(m) {
    dom.get("status").text = "Got {m.path}"
})

// Send to another application, a window in this app, or this page
let target = sys.target("application/x-vnd.Haiku-Tracker")
target.send('GENG', { path: "/boot/home" })

// Request/reply with a callback (never blocks the UI)
target.ask('GETV', { name: "x" }, fn(reply) {
    log(reply)
})
```

`ask` is asynchronous: the reply arrives as an event on the page's looper, so scripts never block on another application.

### 4.3 Haiku scripting suites

Haiku applications expose properties through `B_GET_PROPERTY`, `B_SET_PROPERTY`, `B_COUNT_PROPERTIES` and friends. Gengo wraps these directly, in the spirit of the `hey` command:

```gengo
use script

let tracker = script.target("application/x-vnd.Be-TRAK")

tracker.count("Window", fn(n) {
    log("Tracker has {n} windows")
})

tracker.get("Title", script.window(0), fn(title) {
    log(title)
})

tracker.set("Frame", script.window("Home"), { left: 50, top: 50, right: 700, bottom: 500 })
```

Specifier helpers: `script.index(n)`, `script.reverse_index(n)`, `script.name(s)`, `script.id(n)`, `script.range(a, b)`. Specifiers may be chained to walk the suite hierarchy.

Tororu also **exposes itself** to scripting, so users and other applications can drive it:

```
hey Tororu COUNT Window
hey Tororu GET Title of Window 0
hey Tororu DO "dom.get('x').text = 'hi'"        # runs Gengo in the active page, gated by capability
```

(The exact `hey` syntax above is illustrative and follows the suite once implemented.)

### 4.4 Files, attributes and queries

```gengo
use fs

let text = fs.read("notes.txt")
fs.write("out.txt", text.upper())

// BFS attributes
fs.attr.set("notes.txt", "Notes:Rating", 5)
let rating = fs.attr.get("notes.txt", "Notes:Rating")

// BFS queries
for file in fs.query("(name==\"*.gengo\")&&(last_modified>%1)", [yesterday]) {
    log(file.path)
}

// Node monitoring
let watch = fs.watch("/boot/home/Documents", fn(change) {
    log("{change.kind}: {change.name}")     // created, removed, moved, changed
})
watch.stop()
```

### 4.5 System integration

```gengo
use sys

sys.launch("application/x-vnd.Haiku-StyledEdit")      // by signature, via BRoster
sys.launch("/boot/home/readme.txt")                   // by path
sys.open_url("file:///boot/home/index.html")          // opens in a Tororu window
sys.notify("Done", "Export finished")                 // BNotification
sys.clipboard.set("copied text")
let pasted = sys.clipboard.get()
log(sys.os.version, sys.env.HOME)
```

Nothing shells out. There is deliberately no `sys.exec("a string")`, since it would defeat the capability model; `sys.launch` goes through the roster only.

---

## 5. Binding to HTML (the "DOM-lite")

Tororu's layout engine is small, so Gengo's page API is small and honest about it. There is no CSS and no full DOM.

### 5.1 Loading scripts

```html
<script type="text/gengo" src="app.gengo"></script>

<script type="text/gengo">
    ready(fn() { dom.get("greeting").text = "Hello from Gengo" })
</script>
```

### 5.2 Declarative events

```html
<button id="plus" on:click="increment">+1</button>
<input  id="name" on:input="validate">
<a href="gengo:open_help">Help</a>
```

`on:event="name"` calls the named top-level function with the event map. `gengo:` links call a function without navigating.

### 5.3 The `dom` module

```gengo
let el   = dom.get("total")              // by id, nil if missing
let many = dom.query("li.done")          // tag, #id, .class and "tag.class" only
let item = dom.create("li", { text: "New", class: "todo" })

el.text = "Hello"                        // plain text, escaped
el.html = "<b>Hello</b>"                 // parsed with Tororu's engine
el.attr("href")                          // read
el.set("href", "page2.html")             // write
el.value                                 // form controls
el.hidden = true
el.children                              // list of handles
el.parent
el.append(item)
el.remove()
el.on("click", fn(e) { ... })            // returns a handle with .stop()
```

Mutations are **batched**: the page re-lays out once at the end of the current event turn, not on every assignment.

### 5.4 Events

Event maps always contain `type` and `target`. Others by type:

| Event | Extra fields |
|---|---|
| `click` | `x`, `y`, `button`, `modifiers` |
| `input`, `change` | `value` |
| `key` | `key`, `modifiers`, `repeat` |
| `submit` | `fields` (map of form values) |
| `close` | `cancel()` to veto |
| `drop` | `paths` (list), from BMessage `B_SIMPLE_DATA` drops |

Call `e.stop()` to prevent the default action (such as following a link).

### 5.5 Application and navigation

```gengo
use app
use nav

app.window.title = "Notes"
app.window.size = { width: 640, height: 480 }
app.settings.set("last_file", path)         // auto-saved
let last = app.settings.get("last_file", nil)
app.quit()

nav.go("settings.html")
nav.back()
log(nav.url)
```

`app.settings` is a map stored as a flattened BMessage under `~/config/settings/Tororu/Apps/<signature>/settings`, in line with where Tororu keeps its other settings.

### 5.6 Dialogs

All dialogs are asynchronous and take a callback, because Haiku's `BFilePanel` is message-driven.

```gengo
use dialog

dialog.alert("Saved")
dialog.confirm("Delete this note?", fn(yes) {
    if yes { delete_note() }
})
dialog.open_file({ title: "Open", filter: "text/*" }, fn(path) {
    if path == nil { return }
    editor.text = fs.read(path)
})
dialog.save_file({ name: "untitled.txt" }, fn(path) { ... })
```

---

## 6. Standard library

Kept deliberately small. Modules marked **cap** require a manifest capability (section 9).

| Module | Purpose | Cap |
|---|---|---|
| *(globals)* | `log`, `type`, `len`, `str`, `int`, `num`, `range`, `ready`, `after`, `every`, `on_message`, `assert` | none |
| `math` | `abs floor ceil round min max sqrt pow sin cos tan rand idiv PI` | none |
| `text` | `split join trim upper lower find replace format pad` and regex-lite (`match`, `matches`) | none |
| `data` | `data.parse_json`, `data.to_json`, `data.parse_msg` | none |
| `time` | `time.now`, `time.format`, `time.parse`, `time.sleep` (tasks only) | none |
| `dom` | page access (5.3) | `dom` |
| `app`, `nav` | window, settings, navigation | `app` |
| `dialog` | alerts, confirms, file panels | `dialog` |
| `fs` | files, attributes, queries, watching | `fs:*` |
| `sys` | launch, notify, clipboard, targets | `sys:*` |
| `script` | Haiku scripting client | `script:*` |
| `task` | background workers (section 7) | `task` |

`log(...)` writes to Tororu's debug console window (View > Debug Console) and to `stderr` when launched from Terminal.

---

## 7. Execution model

### 7.1 One interpreter per page

Every page gets its own isolated interpreter instance with its own globals and heap. Interpreters share nothing; there are no global mutable singletons in the runtime.

### 7.2 Single-threaded, event-driven

The interpreter runs on the window's looper thread. Everything is driven by messages: page load, clicks, timers, replies, file watch notifications. One event is handled to completion before the next begins, so scripts need no locks.

```gengo
after(1000, fn() { log("one second later") })       // BMessageRunner, one shot
let t = every(500, fn() { tick() })                 // repeating
t.stop()
```

### 7.3 Tasks for long work

Long work would freeze the window, so Gengo has **tasks**: separate interpreters on their own threads that communicate by copying messages.

```gengo
use task

let worker = task.start("hash.gengo", { path: path })
worker.on("progress", fn(m) { bar.value = m.percent })
worker.on("done",     fn(m) { dom.get("result").text = m.digest })
worker.on("error",    fn(e) { dialog.alert(e.message) })
```

```gengo
// hash.gengo (runs in the worker)
use fs
let total = fs.stat(args.path).size
...
emit("progress", { percent: 50 })
emit("done", { digest: digest })
```

Tasks get a restricted capability subset (no `dom`, `app`, `nav`, `dialog`). Data crossing the boundary is deep-copied through BMessage conversion, which is also why it is limited to BMessage-representable types. Functions and handles cannot be passed.

### 7.4 Watchdog

A step and wall-clock budget applies to each event turn (default 2 seconds on the window thread). Exceeding it aborts that turn with `E_TIMEOUT`, shows the error, and leaves the page alive. Tasks are exempt from the wall-clock limit but can be cancelled with `worker.stop()`.

---

## 8. Implementation design

### 8.1 Pipeline

```
source  ->  lexer  ->  parser  ->  AST  ->  resolver  ->  interpreter
                                            (scopes,     (v0.x: tree walker,
                                             const,       later: bytecode VM)
                                             imports)
```

**Decision:** begin with a tree-walking interpreter over a resolved AST. It is the fastest route to a working language and is fast enough for UI scripting. The embedding API (8.4) is written so the engine can later be replaced by a bytecode VM without changing any host code. Revisit when profiling says it matters.

### 8.2 Values and memory

- `GengoValue` is a 16-byte tagged union: tag plus `int64`, `double`, `bool`, `what`, or a pointer to a heap object.
- Strings are immutable, reference counted, interned for short strings (so map key lookup is a pointer compare).
- Lists, maps, closures and handles are heap objects managed by a **simple mark-and-sweep collector**, run at event-turn boundaries (a safe point with an almost empty stack), and when a heap threshold is crossed.
- Because interpreters are isolated and single threaded, the collector needs no locking and no write barriers.

Rationale: reference counting alone leaks closure and map cycles, which are common in event-driven code. Mark-and-sweep at turn boundaries is simple, predictable and invisible to the user.

### 8.3 Source layout (proposed)

```
src/
  gengo/
    GengoLexer.cpp / .h
    GengoParser.cpp / .h
    GengoAST.h
    GengoResolver.cpp
    GengoInterpreter.cpp / .h
    GengoValue.cpp / .h
    GengoHeap.cpp            // allocation and collector
    GengoMessage.cpp         // value <-> BMessage conversion
    GengoErrors.cpp          // error type and formatting
    lib/                     // one file per standard module
      GengoLibFs.cpp
      GengoLibDom.cpp
      GengoLibScript.cpp
      ...
tests/
  gengo/
    language/*.gengo         // pure-language tests with expected output
    stdlib/*.gengo
    errors/*.gengo           // expected error text and line numbers
tools/
  gengo.cpp                  // standalone CLI: run, repl, check, fmt
```

The language core (`GengoLexer` through `GengoMessage`) depends on the Haiku support kit only for `BMessage` conversion and `BString`, so the lexer, parser, resolver and interpreter can be built and tested on any platform. That matches the existing `make validate` goal of platform-independent consistency checks.

### 8.4 Embedding API (libtororu)

Following the project's conventions (K&R braces, separator comment after each function, Australian English names):

```cpp
// Create an interpreter for a page and expose a native function.
GengoInterpreter* interpreter = new GengoInterpreter(capabilities);

interpreter->RegisterFunction("sys", "launch", &SysLaunch);
//---------------------------------------------------------------------------------------------------------------------------------//

GengoValue SysLaunch(GengoCall& call) {
	BString target = call.ArgString(0);          // throws a Gengo error on type mismatch

	status_t result = be_roster->Launch(target.String());
	if (result != B_OK) {
		return call.Fail("E_LAUNCH", result);     // becomes a catchable Gengo error
	}

	return GengoValue::Nil();
}
//---------------------------------------------------------------------------------------------------------------------------------//

// Run a script and deliver an event.
GengoResult result = interpreter->RunFile("app.gengo");
if (!result.ok) {
	ShowErrorPage(result.error);               // file, line, col, message, source excerpt
}

interpreter->Dispatch("click", eventMessage);  // eventMessage is a BMessage
```

`RegisterFunction` binds a native callback to `module.name`. Calls validate arguments through `GengoCall` helpers so native code stays short and errors are uniform.

### 8.5 Errors

```
app.gengo:14:9  E_TYPE  cannot add str and int

  14 |     total = name + count
     |             ^^^^
```

- Compile errors are collected, not fatal on the first one, up to a small limit.
- Runtime errors carry a call stack (`stack` list of `{ fn, file, line }`).
- Tororu renders them on a built-in error page, matching how it already embeds built-in artwork and pages.

### 8.6 Tooling

- **`gengo` CLI** (also usable from Terminal): `gengo run file.gengo`, `gengo repl`, `gengo check file.gengo` (parse and resolve only), `gengo fmt file.gengo`.
- **Formatter** enforces the house style: K&R braces, four-space indent in Gengo source, no trailing whitespace.
- **Syntax highlighting** definitions for Haiku's StyledEdit and Pe, plus a TextMate grammar for other editors.
- **Debug console** inside Tororu with `log` output and a one-line REPL against the active page.

---

## 9. Security and capabilities

Gengo scripts start with **no authority**. Pure computation, `math`, `text`, `data`, `time` and the page's own `dom` are the only things always allowed.

Each app declares what it needs in `manifest.gengo`, a data-only file (a single map literal, parsed without executing code):

```gengo
{
    name: "Notes",
    signature: "application/x-vnd.example-Notes",
    version: "v0.1",
    entry: "index.html",
    uses: [
        "dom", "app", "dialog",
        "fs:app",              // read/write inside the app folder
        "fs:settings",         // this app's settings folder
        "sys:clipboard",
    ]
}
```

| Capability | Grants |
|---|---|
| `dom`, `app`, `nav`, `dialog`, `task` | the module of that name |
| `fs:app` | the application's own folder |
| `fs:settings` | `~/config/settings/Tororu/Apps/<signature>/` |
| `fs:picked` | only files the user chose via `dialog.open_file` or `save_file` |
| `fs:home` | `/boot/home`, **prompts the user on first use** |
| `fs:any` | whole filesystem, **prompts every session** |
| `sys:clipboard`, `sys:notify`, `sys:launch` | the matching `sys` features |
| `script:<signature>` | scripting a specific application (or `script:*`, which prompts) |

Further rules:

- Paths are canonicalised before checking, so `..` and symlink tricks cannot escape a granted root.
- Documents from outside the app folder (an arbitrary local `.html` opened in Tororu) run with **no capabilities** unless the user explicitly trusts them. Opening a stray file must never grant authority.
- No `eval`, no shell, no dynamic library loading.
- The watchdog (7.4) and a heap ceiling (default 64 MB per interpreter) prevent runaway scripts from taking the machine down.
- Capability checks happen in the host functions, not in the language, so a bug in a script cannot bypass them.

---

## 10. Packaging

A Gengo application is just a folder (or a zip, later an hpkg) that Tororu can open directly:

```
Notes/
  manifest.gengo
  index.html
  app.gengo
  lib/
    format.gengo
  images/
    icon.png
```

`Tororu /boot/home/Notes` runs it. A later milestone can wrap an app folder with the Tororu binary into a self-contained Haiku application with its own signature and icon, using the same `BApplication`-based entry the engine already has.

---

## 11. Example: a small notes app

`index.html`

```html
<html>
<body>
  <h1>Notes</h1>
  <p id="file">No file open</p>
  <textarea id="editor" rows="20" cols="70"></textarea>
  <p>
    <button on:click="open_note">Open</button>
    <button on:click="save_note">Save</button>
  </p>
  <p id="status"></p>
  <script type="text/gengo" src="app.gengo"></script>
</body>
</html>
```

`app.gengo`

```gengo
use dom
use fs
use app
use dialog
use time

let current = nil

fn show(text) {
    dom.get("status").text = text
    after(3000, fn() { dom.get("status").text = "" })
}

fn open_note(e) {
    dialog.open_file({ title: "Open note", filter: "text/*" }, fn(path) {
        if path == nil { return }
        dom.get("editor").value = fs.read(path)
        dom.get("file").text = path
        current = path
        app.settings.set("last", path)
    })
}

fn save_note(e) {
    if current == nil {
        dialog.save_file({ name: "note.txt" }, fn(path) {
            if path != nil {
                current = path
                write_current()
            }
        })
    } else {
        write_current()
    }
}

fn write_current() {
    try {
        fs.write(current, dom.get("editor").value)
        fs.attr.set(current, "Notes:Saved", time.now())
        show("Saved {current}")
    } catch err {
        show("Could not save: {err.message}")
    }
}

ready(fn() {
    let last = app.settings.get("last", nil)
    if last != nil and fs.exists(last) {
        dom.get("editor").value = fs.read(last)
        dom.get("file").text = last
        current = last
    }
})
```

Manifest `uses`: `["dom", "app", "dialog", "fs:settings", "fs:picked"]`.

---

## 12. Required changes to the Tororu engine

Gengo can be developed and tested without any of this (the core runs from the CLI), but a page-driving language needs a few things the current layout engine does not have:

1. **Stable element identity:** `id` and `class` attributes retained on parsed nodes, with lookup by id.
2. **Mutation:** setting text, attributes and child lists, and a **batched relayout** at the end of an event turn.
3. **Form controls:** `<button>`, `<input>` (text, checkbox), `<textarea>`, `<select>`, rendered with native Haiku controls (`BButton`, `BTextControl`, `BTextView`, `BMenuField`) embedded in the layout.
4. **`<script>` tag handling**, `on:*` attributes and `gengo:` links.
5. **Hit-testing** that maps clicks to elements for the event system.
6. **A tiny styling story**, if wanted later. Gengo itself does not depend on CSS. The `hidden` attribute and a handful of presentation attributes may be enough for v1.

Because Tororu intentionally has no JavaScript or CSS today, items 1 to 5 are the whole of the dependency; there is nothing to untangle from an existing script engine.

---

## 13. Milestones

| # | Milestone | Outcome |
|---|---|---|
| M1 | **Core language** | Lexer, parser, resolver, tree-walking interpreter, values, errors, `gengo run/check` CLI, language test suite wired into `make validate` |
| M2 | **Standard library** | `math`, `text`, `data`, `time`, `fs` (no attributes yet), globals, `use` and file modules |
| M3 | **Host embedding** | `libtororu` integration, one interpreter per page, `ready`, timers, error page, debug console |
| M4 | **Page binding** | Engine work from section 12, `dom`, events, `on:*`, `app`, `nav`, `dialog` |
| M5 | **Haiku features** | BMessage conversion, `on_message`/`send`/`ask`, scripting client and Tororu suite, BFS attributes, queries, `fs.watch`, `sys` |
| M6 | **Safety and tasks** | Manifest and capability enforcement, trust prompts, watchdog, heap ceiling, `task` workers |
| M7 | **Polish** | Formatter, highlighting definitions, packaging, bytecode VM if profiling justifies it |

Per the project's versioning rules, each user-visible change bumps the Tororu patch version and gets a CHANGELOG entry; Gengo versions are tracked in the same way and displayed with a small `v` prefix.

---

## 14. Testing

- **Language tests:** every `.gengo` file in `tests/gengo/language` has a sibling `.expected` file. The runner compares standard output and error text including line numbers.
- **Error tests:** one file per error code, asserting the message and caret position.
- **Fuzzing:** a lexer/parser fuzz target to ensure malformed input never crashes the host.
- **Conversion tests:** round-trip `map` <-> `BMessage` for every supported type (Haiku only).
- **Capability tests:** try each denied operation and assert `E_DENIED`.
- `make validate` runs the platform-independent suites. Haiku-only tests run under `make test` on a Haiku machine.

---

## 15. Open questions

1. **Syntax of blocks:** braces were chosen to match the C++ codebase and Haiku developers' habits. Is an indentation or `end`-style syntax preferable for newcomers?
2. **`what` literal:** `'MSG1'` conflicts with nothing today, but would block single-quoted strings. Acceptable?
3. **Forms:** should native Haiku controls embedded in the layout be the only option, or should Tororu draw its own lightweight controls for a consistent look inside the HTML flow?
4. **Network:** Tororu has none today. If it ever gains it, Gengo should add `net` as a capability with per-host grants, never as ambient access. Do you want that reserved now?
5. **Name for `ready`:** alternatives are `on_load` or a manifest-declared `main`.
6. **hpkg packaging:** should app bundles be hpkg-native from the start?
7. **Localisation:** should `str` formatting integrate with Haiku's locale kit (`B_TRANSLATE`-style catalogues) for apps built on Gengo?

---

## 16. Appendix: grammar sketch

```ebnf
program     = { statement } ;
statement   = let | const | fn_decl | export | use | if | for | while
            | match | try | throw | return | break | continue | expr_stmt ;

let         = "let" ident "=" expr ;
const       = "const" ident "=" expr ;
fn_decl     = "fn" ident "(" [ params ] ")" block ;
params      = param { "," param } ;
param       = ident [ "=" expr ] ;
use         = "use" ( ident | string ) [ "as" ident ] ;
export      = "export" ( fn_decl | let | const ) ;

if          = "if" expr block { "else" "if" expr block } [ "else" block ] ;
for         = "for" ident [ "," ident ] "in" expr block ;
while       = "while" expr block ;
match       = "match" expr "{" { expr block } [ "else" block ] "}" ;
try         = "try" block "catch" ident block ;
throw       = "throw" expr ;
return      = "return" [ expr ] ;
block       = "{" { statement } "}" ;

expr        = assignment ;
assignment  = target ( "=" | "+=" | "-=" | "*=" | "/=" | "%=" ) assignment | coalesce ;
coalesce    = or { "??" or } ;
or          = and { "or" and } ;
and         = equality { "and" equality } ;
equality    = comparison { ( "==" | "!=" | "is" ) comparison } ;
comparison  = range { ( "<" | "<=" | ">" | ">=" ) range } ;
range       = additive [ ( ".." | "..=" ) additive ] ;
additive    = multiply { ( "+" | "-" ) multiply } ;
multiply    = unary { ( "*" | "/" | "%" ) unary } ;
unary       = ( "-" | "not" ) unary | postfix ;
postfix     = primary { call | index | "." ident | "?." ident } ;
call        = "(" [ arg { "," arg } ] ")" ;
arg         = [ ident ":" ] expr ;
index       = "[" expr "]" ;
primary     = number | string | what | "nil" | "true" | "false" | ident
            | list | map | fn_expr | "(" expr ")" ;
list        = "[" [ expr { "," expr } ] "]" ;
map         = "{" [ entry { "," entry } ] "}" ;
entry       = ( ident | string ) ":" expr ;
fn_expr     = "fn" "(" [ params ] ")" block ;
```

---

*Gengo is a draft design. Everything here is open to change as Tororu's engine and `libtororu` take shape.*
