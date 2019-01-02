# kakoune-cargo

Cargo compiler support for kakoune
Currently only supports syntax hightlighting

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

No commands are currently supported - just syntax highlighting
