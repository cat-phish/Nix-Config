# Enable the subsequent settings only in interactive sessions
case $- in
    *i*) ;;
    *) return ;;
esac
# Source Home Manager session variables
if [ -f ~/.nix-profile/etc/profile.d/hm-session-vars.sh ]; then
    source ~/.nix-profile/etc/profile.d/hm-session-vars.sh
elif [ -f ~/.local/state/nix/profiles/profile/etc/profile.d/hm-session-vars.sh ]; then
    source ~/.local/state/nix/profiles/profile/etc/profile.d/hm-session-vars.sh
elif [ -f /etc/profiles/per-user/jordan/etc/profile.d/hm-session-vars.sh ]; then
    source /etc/profiles/per-user/jordan/etc/profile.d/hm-session-vars.sh
fi

# Source the .env file if it exists
if [ -f "$HOME/.env" ]; then
    export $(grep -v '^#' $HOME/.env | xargs)
fi

# Path to your oh-my-bash installation.
export OSH='/home/jordan/.oh-my-bash'

alias cdh="cd /home/jordan"
alias cdd="cd .."
alias c="clear"
alias lss="ls -a"

# Delete empty directories including subdirectories
# delete_empty_dirs_bulk() {
#     find . -type d -empty -print
#     echo "Do you want to delete all the above directories? (y/n)"
#     read -r choice
#     if [[ "$choice" == "y" || "$choice" == "Y" ]]; then
#         find . -type d -empty -exec rm -r {} +
#         echo "Deleted all empty directories."
#     else
#         echo "Operation canceled."
#     fi
# }

delete_empty_dirs_bulk() {
    echo "Top-level directories that will remain:"
    find . -mindepth 1 -maxdepth 1 -type d -not -empty
    echo ""
    echo "Directories to delete (item counts shown):"
    find . -type d -empty -print0 | while IFS= read -r -d '' dir; do
        echo "$dir (0 items)"
    done

    echo "Do you want to delete all the above directories? (y/n)"
    read -r choice
    if [[ "$choice" == "y" || "$choice" == "Y" ]]; then
        find . -type d -empty -exec rm -r {} +
        echo "Deleted all empty directories."
    else
        echo "Operation canceled."
    fi

    echo "Top-level directories that will remain:"
    find . -mindepth 1 -maxdepth 1 -type d -not -empty
}

alias refresh-bash="source ~/.bashrc"

# Neovim
alias v="nvim"
alias vv="nvim ."
alias nvim-ssh="~/.scripts/nvim-ssh.sh"
alias nixcats="$HOME/coding/nixCats/result/bin/nvim"

# SSH auto xterm-colors
alias ssh-color="TERM=xterm-256color ssh"

search-zsh-history() {
    grep -a "$1" ~/.zsh_history
}

search-bash-history() {
    grep -a "$1" ~/.bash_history
}

start() {
    tmux new -d -s tmp
    sleep 1
    tmux send-keys -t tmp ./.config/tmux/plugins/tmux-resurrect/scripts/restore.sh Enter
    sleep 2
    tmux kill-session -t tmp
    tmux a -t main
}

# Kmonad
if [[ "$(hostname)" = "jordans-desktop" ]]; then
    kmonad-refresh() {
        systemctl --user restart kmonad_keychron_k2_pro.service
        systemctl --user restart kmonad_havit.service
        systemctl --user restart kmonad_winry315.service
    }
elif [[ "$(hostname)" = "jordans-laptop" ]]; then
    alias kmonad-refresh="systemctl --user restart kmonad_legion_slim_7.service"
fi

# Tmux
alias t="tmux"
alias tl="tmux ls"
alias ta="tmux a -t"
alias tam="tmux a -t main"
alias tn="tmux new -s"
alias tk="tmux kill-session -t"
alias tmux-refresh="tmux source ~/.config/tmux/tmux.conf"

tmux-fix() {
    tmux detach
    tmux kill-server
    tmux new -- bash --noprofile --norc
    tmux source ~/.config/tmux/tmux.conf
    tmux kill-session -t 0
    tmux new-session -s main
}

tim() {
    tmux send-keys -t main:0.2 'bpytop' Enter
    tmux send-keys -t main:0.1 'neo-matrix' Enter
    tmux a -t main
}

tin() {
    if [[ -z "$1" ]]; then
        echo "No session name provided"
        return
    fi
    tmux new -d -s "$1"
    tmux splitw -h -t "$1"
    tmux splitw -v -p 70 -t "$1"
    tmux send-keys -t "$1":0.1 'neo-matrix' Enter
    tmux selectp -t "$1":0.0
    tmux renamew -t "$1":0 'sys'
    source ~/.scripts/tmux_init "$1" &
    tmux a -t "$1"
}

ts() {
    tmux new -d -s tmp
    sleep 1
    tmux send-keys -t tmp ./.config/tmux/plugins/tmux-resurrect/scripts/restore.sh Enter
    sleep 2
    tmux kill-session -t tmp
    tmux a -t main
}

# Git
alias g="git"
alias gs="git status"
ga() {
    git add "$1"
}
alias gaa="git add ."
gcm() {
    git commit -m "$1"
}
alias gpu="git push"
alias gpl="git pull"
gac() {
    if [[ -z "$1" ]]; then
        echo "No commit message provided"
        return
    fi
    git add .
    git commit -m "$1"
}
gacp() {
    if [[ -z "$1" ]]; then
        echo "No commit message provided"
        return
    fi
    git add .
    git commit -m "$1"
    git push
}
alias gco="git checkout"
alias gcob="git checkout -b"

# Run scripts from ~/.scripts with completion
scripts() {
    "$HOME/.scripts/$1"
}
_scripts_completion() {
    local cur
    cur="${COMP_WORDS[COMP_CWORD]}"
    COMPREPLY=( $(compgen -W "$(ls $HOME/.scripts/)" -- "$cur") )
}
complete -F _scripts_completion scripts

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"                   # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion" # This loads nvm bash_completion

[ -f ~/.fzf.bash ] && source ~/.fzf.bash

# Add ~/.local/bin to path
# export PATH="$HOME/.local/bin:$PATH"

# alias sdm="$HOME/.config/sdm/sdm"

function sdm() {
    source "$HOME/.config/sdm/sdm" "$@"
}

# Add autocompletion for SDM
source "$HOME/.config/sdm/lib/sdm_bash_completion"

### OH-MY-BASH CONFIG ###

# Set name of the theme to load. Optionally, if you set this to "random"
# it'll load a random theme each time that oh-my-bash is loaded.
OSH_THEME="agnoster"

# Uncomment the following line to use case-sensitive completion.
# OMB_CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion. Case
# sensitive completion must be off. _ and - will be interchangeable.
# OMB_HYPHEN_SENSITIVE="false"

# Uncomment the following line to disable bi-weekly auto-update checks.
# DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to change how often to auto-update (in days).
# export UPDATE_OSH_DAYS=13

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you don't want the repository to be considered dirty
# if there are untracked files.
# SCM_GIT_DISABLE_UNTRACKED_DIRTY="true"

# Uncomment the following line if you want to completely ignore the presence
# of untracked files in the repository.
# SCM_GIT_IGNORE_UNTRACKED="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.  One of the following values can
# be used to specify the timestamp format.
# * 'mm/dd/yyyy'     # mm/dd/yyyy + time
# * 'dd.mm.yyyy'     # dd.mm.yyyy + time
# * 'yyyy-mm-dd'     # yyyy-mm-dd + time
# * '[mm/dd/yyyy]'   # [mm/dd/yyyy] + [time] with colors
# * '[dd.mm.yyyy]'   # [dd.mm.yyyy] + [time] with colors
# * '[yyyy-mm-dd]'   # [yyyy-mm-dd] + [time] with colors
# If not set, the default value is 'yyyy-mm-dd'.
# HIST_STAMPS='yyyy-mm-dd'

# Uncomment the following line if you do not want OMB to overwrite the existing
# aliases by the default OMB aliases defined in lib/*.sh
# OMB_DEFAULT_ALIASES="check"

# Would you like to use another custom folder than $OSH/custom?
# OSH_CUSTOM=/path/to/new-custom-folder

# To disable the uses of "sudo" by oh-my-bash, please set "false" to
# this variable.  The default behavior for the empty value is "true".
OMB_USE_SUDO=true

# To enable/disable display of Python virtualenv and condaenv
# OMB_PROMPT_SHOW_PYTHON_VENV=true  # enable
# OMB_PROMPT_SHOW_PYTHON_VENV=false # disable

# Which completions would you like to load? (completions can be found in ~/.oh-my-bash/completions/*)
# Custom completions may be added to ~/.oh-my-bash/custom/completions/
# Example format: completions=(ssh git bundler gem pip pip3)
# Add wisely, as too many completions slow down shell startup.
completions=(
    git
    composer
    ssh
)

# Which aliases would you like to load? (aliases can be found in ~/.oh-my-bash/aliases/*)
# Custom aliases may be added to ~/.oh-my-bash/custom/aliases/
# Example format: aliases=(vagrant composer git-avh)
# Add wisely, as too many aliases slow down shell startup.
aliases=(
    general
)

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-bash/plugins/*)
# Custom plugins may be added to ~/.oh-my-bash/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(
    git
    bashmarks
)

# Which plugins would you like to conditionally load? (plugins can be found in ~/.oh-my-bash/plugins/*)
# Custom plugins may be added to ~/.oh-my-bash/custom/plugins/
# Example format:
#  if [ "$DISPLAY" ] || [ "$SSH" ]; then
#      plugins+=(tmux-autoattach)
#  fi

source "$OSH"/oh-my-bash.sh

# User configuration
# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

export VISUAL='nvim'
export EDITOR='$VISUAL'

# Source Home Manager session variables
if [ -f ~/.nix-profile/etc/profile.d/hm-session-vars.sh ]; then
    source ~/.nix-profile/etc/profile.d/hm-session-vars.sh
elif [ -f ~/.local/state/nix/profiles/profile/etc/profile.d/hm-session-vars.sh ]; then
    source ~/.local/state/nix/profiles/profile/etc/profile.d/hm-session-vars.sh
elif [ -f /etc/profiles/per-user/jordan/etc/profile.d/hm-session-vars.sh ]; then
    source /etc/profiles/per-user/jordan/etc/profile.d/hm-session-vars.sh
fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# ssh
# export SSH_KEY_PATH="~/.ssh/rsa_id"

# Set personal aliases, overriding those provided by oh-my-bash libs,
# plugins, and themes. Aliases can be placed here, though oh-my-bash
# users are encouraged to define aliases within the OSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias bashconfig="mate ~/.bashrc"
# alias ohmybash="mate ~/.oh-my-bash"

