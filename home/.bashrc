#!/bin/bash
# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
# HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend
# Save multi-line commands as one command
shopt -s cmdhist

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=1000000
HISTFILESIZE=1000000

# Avoid duplicates
HISTCONTROL=ignoreboth

# After each command, append to the history file and reread it
# PROMPT_COMMAND="${PROMPT_COMMAND:+$PROMPT_COMMAND$'\n'}history -a; history -n"
PROMPT_COMMAND='history -a; history -n'
trap 'history -a; history -n' DEBUG
# trap 'history -a; history -n; printf "\033]0;%s\007" "$BASH_COMMAND"' DEBUG
# trap 'history -a; history -n; printf "\033]0;%s\007" "$(history 1 | sed "s/^[ ]*[0-9]\+[ ]*//")"' DEBUG

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
#shopt -s globstar

# make less more friendly for non-text input files, see lesspipe(1)
#[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    alias dir='dir --color=auto'
    alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# colored GCC warnings and errors
export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

# some more ls aliases
alias ll='ls -l'
alias la='ls -A'
alias l='ls -CF'

# Alias definitions.
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.

if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi


if [ -f "/usr/share/git/git-prompt.sh" ]; then
    # Arch location
    source "/usr/share/git/git-prompt.sh"
elif [ -f "/usr/lib/git-core/git-sh-prompt" ]; then
    # Debian/Ubuntu location
    source "/usr/lib/git-core/git-sh-prompt"
elif [ -f "/usr/share/git-core/contrib/completion/git-prompt.sh" ]; then
    # Fedora / RHEL location
    source "/usr/share/git-core/contrib/completion/git-prompt.sh"
fi

bind 'set completion-ignore-case on'
bind '"\e[A": history-search-backward'
bind '"\e[B": history-search-forward'
bind '"\eOA": history-search-backward'
bind '"\eOB": history-search-forward'
bind 'TAB:complete'
bind '"\e[Z":menu-complete-backward'

if command -v fzf &>/dev/null; then
    # source <(fzf --bash) if fzf --version >= 0.48.0
    if [ -f /usr/share/doc/fzf/examples/key-bindings.bash ]; then
        . /usr/share/doc/fzf/examples/key-bindings.bash
    else
        source <(fzf --bash)
    fi
    # Open fzf history on arrow up
    bind -x '"\e[A": "__fzf_history__"'
fi

print_right_arrow() {
    #\u2B80
    printf '\uE0B0'
}

print_left_arrow() {
    printf '\uE0B2'
}

show_exit_status() {
    code=$?
    if [[ ! $code == "0" ]]; then
        #echo -e "\e[0;31m\e[47m \u2718 "
        echo -e "\e[0;31m\e[40m$(print_right_arrow) "
    else
        #echo -e "\e[0;32m\e[47m \u2714 "
        echo -e "\e[0;32m\e[40m$(print_right_arrow) "
    fi
}


parse_kube_ctx() {
    #\u2388 kube logo
    kube_ctx=$(kubectl config current-context 2> /dev/null)
    if [[ -z $kube_ctx ]]; then
        kube_ctx=""
    else
        kube_ns=$(kubectl config view --minify -o jsonpath={..namespace})
        if [[ -z $kube_ns ]]; then
            kube_ns="default"
        fi
        kube_ctx="$kube_ctx [$kube_ns]"
    fi

    if [[ ! $kube_ctx == "" ]]; then
        echo -e "\e[0;37m\e[40m\u2388 $kube_ctx "
    fi
}

parse_git_branch() {
    #ref="$(git rev-parse --abbrev-ref HEAD 2> /dev/null)"
    ref=$(__git_ps1 '%s')
    if [[ ! -z $ref ]]; then
        if git diff --quiet ; then
            # If no diff show green background
            echo -e "\e[0;30m\e[42m$(print_right_arrow)\e[0;30m\e[42m \uE0A0 $ref \e[0;32m\e[44m$(print_right_arrow)"
        else
            # Else show yellow background with plus-minus sign
            echo -e "\e[0;30m\e[43m$(print_right_arrow)\e[0;30m\e[43m \uE0A0 $ref \u00B1 \e[0;33m\e[44m$(print_right_arrow)"
        fi
    else
        echo -e "\e[0;30m\e[44m$(print_right_arrow)"
    fi
}

current_dir="\e[0;30m\e[44m \w \]\]\e[0;34m$(print_right_arrow)"

# set window title to path, will be ~/asdf if $HOME/asdf
set_title="\[\e]0;\w\a\]"

PS1="$set_title\n\$(show_exit_status)\$(parse_kube_ctx)\$(parse_git_branch)$current_dir\[\e[00m\] \n$ "

export PATH=$PATH:$HOME/.local/bin

export GOROOT=$HOME/.local/go
export GOPATH=$HOME/go
export PATH=$PATH:$GOROOT/bin:$GOPATH/bin
export PATH=$PATH:$HOME/.cargo/bin

alias vim="nvim"
alias vi="nvim"
alias kc="kubectl config use-context"
alias code="codium"

if [ -f $HOME/.config/bashenvs ]; then
    source $HOME/.config/bashenvs
fi

# kubectl completion
if command -v kubectl &>/dev/null; then
    source <(kubectl completion bash)
fi

# flux completion
if command -v flux &>/dev/null; then
    source <(flux completion bash)
fi

# Add non generic extra stuff, like work specific stuff
if [ -f $HOME/.bashrc_extra ]; then
    source $HOME/.bashrc_extra
fi
