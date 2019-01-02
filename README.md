# kakoune-cargo

Cargo compiler support for kakoune
Currently only supports syntax hightlighting, and pressing <ret> on an error/warning to jump

# Install

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
