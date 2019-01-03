
#######################
# Syntax highlighting #
#######################
add-highlighter shared/cargo group
add-highlighter shared/cargo/items regions
add-highlighter shared/cargo-share regions

# shared highlighters
# seperate region set in shared/ so it is not loaded by default
# these are used in both error and warning message region items
add-highlighter shared/cargo-share/rust region "^[0-9]+ \|" $ ref rust
add-highlighter shared/cargo-share/help region "^\s+\|" $ regions
add-highlighter shared/cargo-share/help/rust region "`" "`" ref rust
add-highlighter shared/cargo-share/help/info default-region group
add-highlighter shared/cargo-share/help/info/help regex "help" 0:default+b
add-highlighter shared/cargo-share/attribute region "#\[" \] ref rust

# regional highlights

# error message
add-highlighter shared/cargo/items/error region "^error\[E[0-9]+\]:" "^\n" group
add-highlighter shared/cargo/items/error/context group
add-highlighter shared/cargo/items/error/error regex "^(error)\[(E[0-9]+)\]" 1:red+b 2:cyan
add-highlighter shared/cargo/items/error/arrow regex "(?S)(-->) (.+):([0-9]+):([0-9]+)" 1:red 2:default+b 3:cyan 4:cyan
add-highlighter shared/cargo/items/error/context/pointer regex "\s(-+|\^+)\s" 1:red+b
add-highlighter shared/cargo/items/error/context/share ref cargo-share

# warning message
add-highlighter shared/cargo/items/warning region "^(warning):" "^\n" group
add-highlighter shared/cargo/items/warning/context group
add-highlighter shared/cargo/items/warning/warning regex "^(warning)\[(E[0-9]+)\]" 1:yellow+b 2:cyan
add-highlighter shared/cargo/items/warning/arrow regex "(?S)(-->) (.+):([0-9]+):([0-9]+)" 1:yellow 2:default+b 3:cyan 4:cyan
add-highlighter shared/cargo/items/warning/context/pointer regex "\s(-+|\^+)\s" 1:yellow+b
add-highlighter shared/cargo/items/warning/context/share ref cargo-share

# finished message
add-highlighter shared/cargo/items/finished region "^\s+Finished dev" $ group
add-highlighter shared/cargo/items/finished/finished regex "Finished dev" 0:green+b
add-highlighter shared/cargo/items/finished/flags regions
add-highlighter shared/cargo/items/finished/flags/flags region \[ \] group
add-highlighter shared/cargo/items/finished/flags/flags/flag regex '[a-zA-Z0-9_\-]+' 0:cyan
add-highlighter shared/cargo/items/finished/seconds regex "in ([0-9]+\.[0-9]+)s" 1:default+b

# global highlighters
add-highlighter shared/cargo/error regex "^(error):" 1:red+b
add-highlighter shared/cargo/compile regex "^\s+Compiling" 0:green+b
add-highlighter shared/cargo/check regex "^\s+Checking" 0:yellow
add-highlighter shared/cargo/lineno regex "^([0-9]+) (\|)" 1:cyan+b 2:default


#########
# Hooks #
#########
hook -group cargo-make global WinSetOption compiler=cargo.* %{
    hook -group cargo-hooks window WinSetOption filetype=make %{
        # persist makecmd
        set-option window makecmd cargo
        add-highlighter window/cargo ref cargo
    }

    hook -group cargo-hooks window WinSetOption filetype=(?!make).* %{
        remove-highlighter window/cargo
    }
}

hook -group cargo-make global WinSetOption compiler=(?!cargo).* %{
    remove-hooks window cargo-hooks
}

define-command -hidden -override make-jump %{
    evaluate-commands -try-client %opt{jumpclient} -save-regs 123 %{
        try %{
            # select custom surrounding object
            execute-keys "gl<a-a>c^(?:error\[E[0-9]+\])|(?:warning:),^$<ret>"
            # select file desc
            execute-keys "s(?S)--> (.+):([0-9]+):([0-9]+)<ret><a-;>;"
        } catch %{
            fail "no valid warning/error selected"
        }
        # open
        edit -existing %reg{1} %reg{2} %reg{3}
    }
}

