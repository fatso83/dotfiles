if status is-interactive
    # Commands to run in interactive sessions can go here
end

if test -x $HOME/.local/bin/mise
    if status is-interactive
        $HOME/.local/bin/mise activate fish | source
    else
        $HOME/.local/bin/mise activate fish --shims | source
    end
end

starship init fish | source
