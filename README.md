# kakoune-cargo

Cargo compiler support for kakoune
Adds syntax highlighting, <ret> on errors/warnings to jump to file, and supports make-(next|previous)-error

# Install

Currently requires [kakoune-mouvre](https://github.com/krornus/kakoune-mouvre) in order to
support non-wrapping next/previous errors.

Place in autoload/ or use [plug.kak](https://github.com/andreyorst/plug.kak).

Place the following in your rc or autoload:
```
hook -group make-rust global WinSetOption filetype=rust %[
    set-option window makecmd cargo
    set-option global compiler cargo
]
```

# Usage

Hover over an error or warning section and press <enter> to jump to the given file/line/column entry
Use the commands make-next-error and make-previous error to jump between errors
