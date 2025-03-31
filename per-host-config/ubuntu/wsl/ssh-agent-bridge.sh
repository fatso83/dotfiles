#!/bin/sh
# https://dev.to/d4vsanchez/use-1password-ssh-agent-in-wsl-2j6m

# Code extracted from https://stuartleeks.com/posts/wsl-ssh-key-forward-to-windows/ with minor modifications
__1password_ssh__MATCH_RE='[n]piperelay.exe -ei -s //./pipe/openssh-ssh-agent'

__1password_ssh__check_running(){
    # need `ps -ww` to get non-truncated command for matching
    # use square brackets to generate a regex match for the process we want but that doesn't match the grep command running it!
    ALREADY_RUNNING="$(ps -auxww | grep -q "$__1password_ssh__MATCH_RE"; echo $?)"
    return $ALREADY_RUNNING
}

__1password_ssh__start(){

    # Configure ssh forwarding
    # An alternative is to simply configure this in the config:
    # Host *
    #    IdentityAgent ~/.1password/agent.sock
    export SSH_AUTH_SOCK=$HOME/.1password/agent.sock

    __1password_ssh__check_running

    if [[ "$ALREADY_RUNNING" != "0" ]]; then
        if [[ -S $SSH_AUTH_SOCK ]]; then
            # not expecting the socket to exist as the forwarding command isn't running (http://www.tldp.org/LDP/abs/html/fto.html)
            echo "removing previous socket..."
            rm $SSH_AUTH_SOCK
        fi
        echo "Starting SSH-Agent relay..."
        # setsid to force new session to keep running
        # set socat to listen on $SSH_AUTH_SOCK and forward to npiperelay which then forwards to openssh-ssh-agent on windows
        (setsid socat UNIX-LISTEN:$SSH_AUTH_SOCK,fork EXEC:"npiperelay.exe -ei -s //./pipe/openssh-ssh-agent",nofork &) >/dev/null 2>&1
    fi
}

__1password_ssh__stop(){
    local running_pid

    running_pid=$(ps -auxww | grep "$__1password_ssh__MATCH_RE"  | awk '{print $2}')
    if [[ -z "$running_pid" ]]; then 
        return
    fi

    unset SSH_AUTH_SOCK
    kill $running_pid
    echo "Killed socat ssh agent relay with pid $running_pid"
}

__1password_ssh__restart(){
    __1password_ssh__stop
    __1password_ssh__start
}
