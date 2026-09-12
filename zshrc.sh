# always source zprofile regardless of whether this is/isn't a login shell
source ~/.zprofile

# load shared shell configuration
source ~/.shrc

# load LastPass-backed service logins (ssh, github, claude, ...)
source ~/.credlogin

# the GitHub token every shell used to set up for itself, now one credlogin
# instance among the rest: the gh CLI's own token, from the shell cache after
# the first shell of the week. Silent because a machine without gh, or one
# whose gh is not logged in, is not an error worth a line at every prompt.
credlogin login github gh &>/dev/null

# History file
export HISTFILE=~/.zsh_history

# Don't show duplicate history entires
setopt hist_find_no_dups

# Remove unnecessary blanks from history
setopt hist_reduce_blanks

# Share history between instances
setopt share_history

# Don't hang up background jobs
setopt no_hup

# autocorrect command spelling
setopt correct

# use emacs bindings even with vim as EDITOR
bindkey -e

# fix backspace on Debian
[ -n "$LINUX" ] && bindkey "^?" backward-delete-char

# fix delete key on macOS
[ -n "$MACOS" ] && bindkey '\e[3~' delete-char

# alternate mappings for Ctrl-U/V to search the history
bindkey "^u" history-beginning-search-backward
bindkey "^v" history-beginning-search-forward

# enable autosuggestions
ZSH_AUTOSUGGESTIONS="$HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
[ -f "$ZSH_AUTOSUGGESTIONS" ] && source "$ZSH_AUTOSUGGESTIONS"

# More colours with grc
# shellcheck disable=SC1090
GRC_ZSH="$HOMEBREW_PREFIX/etc/grc.zsh"
[ -f "$GRC_ZSH" ] && source "$GRC_ZSH"

# zsh-specific aliases
alias zmv="noglob zmv -vW"
alias rake="noglob rake"
alias be="noglob bundle exec"

# setup direnv
quiet_which direnv && eval "$(direnv hook zsh)"

# to avoid non-zero exit code
true
