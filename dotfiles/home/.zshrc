# Kali-inspired Zsh setup for Debian.
# This file is only used when Zsh is started; Bash remains the login shell.

# History
HISTFILE="$HOME/.zsh_history"
HISTSIZE=10000
SAVEHIST=10000
setopt append_history
setopt hist_ignore_dups
setopt hist_ignore_space
setopt share_history

# Completion
autoload -Uz compinit
compinit
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

# Friendly interactive behavior
setopt auto_cd
setopt interactive_comments
bindkey -e

# Colors and familiar aliases
autoload -Uz colors && colors
if command -v dircolors >/dev/null 2>&1; then
  eval "$(dircolors -b)"
fi
alias ls='ls --color=auto'
alias ll='ls -alF --color=auto'
alias la='ls -A --color=auto'
alias l='ls -CF --color=auto'
alias grep='grep --color=auto'

# Kali-style two-line prompt. Root gets a red #; normal users get a blue $.
PROMPT=$'%F{blue}┌──(%B%F{cyan}%n㉿%m%f%b%F{blue})-[%B%F{white}%~%f%b%F{blue}]\n└─%B%(#.%F{red}#.%F{blue}$)%b%f '
RPROMPT='%(?..%F{red}[%?]%f)'

# Light gray suggestions; accept with Right Arrow or End.
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=8'
source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh

# Must be sourced last so it can color the completed command line.
source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
