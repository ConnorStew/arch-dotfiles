#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# SSH agent
export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/ssh-agent.socket"

alias ls='ls --color=auto'
alias grep='grep --color=auto'

# Fixing display issues when sshing using kitty.
[[ "$TERM" == "xterm-kitty" ]] && alias ssh='kitten ssh'

PS1='[\u@\h \W]\$ '