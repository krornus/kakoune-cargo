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

# error message
add-highlighter shared/cargo/items/error region "^error" "^\n" group
add-highlighter shared/cargo/items/error/context group
add-highlighter shared/cargo/items/error/error regex "^(error)(?:\[(E[0-9]+)\])?" 1:red+b 2:cyan
add-highlighter shared/cargo/items/error/arrow regex "(?S)(-->) (.+):([0-9]+):([0-9]+)" 1:red 2:default+b 3:cyan 4:cyan
add-highlighter shared/cargo/items/error/context/pointer regex "\s(-+|\^+)\s" 1:red+b
add-highlighter shared/cargo/items/error/context/share ref cargo-share

# warning message
add-highlighter shared/cargo/items/warning region "^(warning)" "^\n" group
add-highlighter shared/cargo/items/warning/context group
add-highlighter shared/cargo/items/warning/warning regex "^(warning)(?:\[(E[0-9]+)\])?" 1:yellow+b 2:cyan
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

###########
# Options #
###########
declare-option str compiler
declare-option str cargo_project_directory

#####################
# Highlighter Hooks #
#####################
hook -group cargo-make global WinSetOption compiler=cargo %{
    # if the filetype is already make, the hook will not run by default
    evaluate-commands %sh{
        if [ "${kak_opt_filetype}" = "make" ]; then
            echo "
                set-option window makecmd cargo
                add-highlighter window/cargo ref cargo
            "
        fi
    }

    hook -group cargo-hooks window WinSetOption filetype=make %{
        # persist makecmd
        set-option window makecmd cargo
        add-highlighter window/cargo ref cargo
    }

    hook -group cargo-hooks window WinSetOption filetype=(?!make).* %{
        remove-highlighter window/cargo
    }
}

hook -group cargo-compiler global WinSetOption compiler=(?!cargo).* %{
    remove-highlighter window/cargo
    remove-hooks window cargo-hooks
}

############
# Commands #
############

# Fail if the kakoune-mouvre plugin is not loaded
#   used for search-no-wrap functionality
try %{ nop %opt{mouvre_version} } catch %{ fail "requires kakoune-mourve" }

define-command -hidden cargo-jump %{
    evaluate-commands -try-client %opt{toolsclient} -save-regs 123456789 %{
        try %{
            # select custom surrounding object
            execute-keys \
                "gl<a-a>c^(?:error)|(?:warning),^$<ret>" \
                "s(?S)--> (.+):([0-9]+):([0-9]+)<ret><a-;>;"
        } catch %{
            fail "no valid warning/error selected"
        }

        set-option buffer make_current_error_line %val{cursor_line}
        cargo-error-directory
        # try-client discards the capture registers
        # make the command with shell first
        evaluate-commands %sh{
            epath=$(echo ${kak_reg_1} | tr -d "'")
            case "$epath" in
                /*) file="$epath" ;;
                *) file="${kak_opt_cargo_project_directory}/${epath}" ;;
            esac
            echo "
            evaluate-commands -try-client %{${kak_opt_jumpclient}} %{
                edit ${file} ${kak_reg_2} ${kak_reg_3}
            }"
        }
    }
}

define-command -hidden cargo-error-directory %{
    evaluate-commands -save-regs s123456789 %{
        execute-keys '"sZ<a-/>(?S)^\s+(?:Checking)|(?:Compiling).+\((.+)\)$<ret>'
        set-option window cargo_project_directory %reg{1}
        execute-keys '"sz<esc>'
    }
}

define-command -hidden cargo-next-error %{
    evaluate-commands -try-client %opt{toolsclient} -save-regs a %{
        execute-keys '"aZ'
        try %{
            buffer "*make*"
            execute-keys "gk%opt{make_current_error_line}g"
            try %{ execute-keys "<esc><a-a>c^(?:error)|(?:warning),^$<ret><a-:>l" }
            search-no-wrap "^(?:error)|(?:warning)"
            cargo-jump
        } catch %{
            execute-keys '"az<esc>'
            fail "no items remaining"
        }
    }
}

define-command -hidden cargo-previous-error %{
    evaluate-commands -try-client %opt{toolsclient} -save-regs a %{
        execute-keys '"aZ'
        try %{
            buffer "*make*"
            execute-keys "gk%opt{make_current_error_line}g"
            try %{ execute-keys "<esc><a-a>c^(?:error)|(?:warning),^$<ret><a-:><a-;>h" }
            reverse-search-no-wrap "^(?:error)|(?:warning)"
            cargo-jump
        } catch %{
            execute-keys '"az<esc>'
            fail "no items remaining"
        }
    }
}

#########
# Hooks #
#########

# this overrides the standard make commands
# if this is problematic, you should make a local make.kak file
# in your autoload which just contains these three original
# functions (renamed) along with a hook for compiler=make which
# rewrites these functions back to the original state
hook -group cargo-compiler global WinSetOption compiler=cargo %{
    define-command -hidden -override make-jump cargo-jump
    define-command -override make-next-error cargo-next-error
    define-command -override make-previous-error cargo-previous-error
}

