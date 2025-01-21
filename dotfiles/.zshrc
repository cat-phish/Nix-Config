# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.config/.emacs.d/bin:$PATH"
# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# TODO: add nixos update shortcuts to here and bashrc

# Source Home Manager session variables
if [ -f ~/.nix-profile/etc/profile.d/hm-session-vars.sh ]; then
  source ~/.nix-profile/etc/profile.d/hm-session-vars.sh
elif [ -f ~/.local/state/nix/profiles/profile/etc/profile.d/hm-session-vars.sh ]; then
  source ~/.local/state/nix/profiles/profile/etc/profile.d/hm-session-vars.sh
elif [ -f /etc/profiles/per-user/jordan/etc/profile.d/hm-session-vars.sh ]; then
  source /etc/profiles/per-user/jordan/etc/profile.d/hm-session-vars.sh
fi

# Source the .env file if it exists
if [ -f "$HOME/.env/.env" ]; then
  set -a  # Automatically export all variables
  source "$HOME/.env/.env"
  set +a  # Disable automatic export
fi

### Aliases ###

# TODO: decide if I want to keep this
# # SDM
# alias sdm="$HOME/.config/sdm/sdm"
# # function sdm() {
# #    source "$HOME/.config/sdm/sdm" "$@"
# # }
# # Add autocompletion for SDM
# source "$HOME/.config/sdm/lib/sdm_zsh_completion"

# General
alias cdh="cd ~"
alias cdd="cd .."
alias c="clear"
alias lss="ls -a"

# Delete empty directories including subdirectories
# function delete_empty_dirs_bulk() {
#   find . -type d -empty -print
#   echo "Do you want to delete all the above directories? (y/n)"
#   read -q "choice?"; echo
#   if [[ "$choice" == "y" ]]; then
#     find . -type d -empty -exec rm -r {} +
#     echo "Deleted all empty directories."
#   else
#     echo "Operation canceled."
#   fi
# }

function delete_empty_dirs_bulk() {
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
}

alias refresh-zsh="source ~/.zshrc"

# Neovim
alias v="nvim"
alias vv="nvim ."
alias nvim-ssh="~/.scripts/nvim-ssh.sh"
alias nixcats="$HOME/coding/nixCats/result/bin/nvim"

# Emacs
alias org="emacs --init-directory=~/.config/emacs"

# SSH auto xterm-colors
alias ssh-color="TERM=xterm-256color ssh"

function search-zsh-history() {
   grep -a "$1" ~/.zsh_history
}
function search-bash-history() {
   grep -a "$1" ~/.bash_history
}
function start() {
   tmux new -d -s tmp
   sleep 1
   tmux send-keys -t tmp ./.config/tmux/plugins/tmux-resurrect/scripts/restore.sh Enter
   sleep 2
   tmux kill-session -t tmp
   tmux a -t main
}

# Run scripts with completion
# # if ! command -v run &> /dev/null; then
run() {
  "$HOME/.scripts/$1"
}
_run_completion() {
  local -a scripts
  scripts=(${(f)"$(ls $HOME/.scripts/)"})
  _describe 'script' scripts
}
compdef _run_completion run
# # fi

# Kmonad
if [[ "$(hostname)" = "jordans-desktop" ]]; then
   function kmonad-refresh() {
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
function tmux-fix() {
   tmux detach
   tmux kill-server
   tmux new -- bash --noprofile --norc
   tmux source ~/.config/tmux/tmux.conf
   tmux kill-session -t 0
   tmux new-session -s main
}
function tim() {
	tmux send-keys -t main:0.2 'bpytop' Enter
	tmux send-keys -t main:0.1 'neo-matrix' Enter
	tmux a -t main
}
function tin() {
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
function ts() {
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
function ga() {
   git add "$1"
}
alias gaa="git add ."
function gcm() {
   git commit -m $1
}

# alias gcm="git commit -m"

alias gpu="git push"
alias gpl="git pull"
function gac() {
   if [[ -z "$1" ]]; then
      echo "No commit message provided"
      return
   fi
   git add .
   git commit -m "$1"
}
function gacp() {
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


### OH-MY-ZSH CONFIG ###

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
#ZSH_THEME="thm"

#
# Requires a nerdfont compatible font to display properly
#
# https://github.com/ryanoasis/nerd-fonts
#
#
function last_two_dir {
  # if we're at ~/ just display ~
  if [ $PWD = $HOME ]; then
    echo '%c'
  # display cwd and parent directory
  else
    echo '%2d'
  fi
}

function display_git {
  if [ $(git_current_branch) ]; then
    echo " {$(git_current_branch)}"
  fi
}

# local cwd_color=040
# local git_branch_color=028
# local arrow_color=040
# local arrow=''

local cwd_color=255
local git_branch_color=028
local arrow_color=255
local arrow=''

# add indicator for when inside vim spawned shell
if [ $VIMRUNTIME ]; then
  arrow_color=196
  arrow=' '
fi

PROMPT='%{$FG[$cwd_color]%}$(last_two_dir)%{$FG[$git_branch_color]%}$(display_git) \
%{$FG[$arrow_color]%}$arrow%{$reset_color%} '

RPROMPT='$(git_prompt_status)%{$reset_color%}'

ZSH_THEME_GIT_PROMPT_ADDED="%{$fg[green]%} ✚"
ZSH_THEME_GIT_PROMPT_MODIFIED="%{$fg[blue]%} ✹"
ZSH_THEME_GIT_PROMPT_DELETED="%{$fg[red]%} ✖"
ZSH_THEME_GIT_PROMPT_RENAMED="%{$fg[magenta]%} ➜"
ZSH_THEME_GIT_PROMPT_UNMERGED="%{$fg[yellow]%} ═"
ZSH_THEME_GIT_PROMPT_UNTRACKED="%{$fg[cyan]%} ✭"


# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder


### OH-MY-ZSH PLUGINS ###

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(
   git
   history-substring-search
   colored-man-pages
   fzf
)

source $ZSH/oh-my-zsh.sh

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

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh


### ZINIT PLUGIN MANAGER ###

# Install zinit if not installed
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
[ ! -d $ZINIT_HOME ] && mkdir -p "$(dirname $ZINIT_HOME)"
[ ! -d $ZINIT_HOME/.git ] && git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
source "${ZINIT_HOME}/zinit.zsh"
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit

# Load a few important annexes, without Turbo
# (this is currently required for annexes)
zinit light-mode for \
    zdharma-continuum/zinit-annex-as-monitor \
    zdharma-continuum/zinit-annex-bin-gem-node \
    zdharma-continuum/zinit-annex-patch-dl \
    zdharma-continuum/zinit-annex-rust

zinit ice depth=1
zinit light jeffreytse/zsh-vi-mode
zinit ice wait"1" lucid
zinit light zsh-users/zsh-autosuggestions
zinit light zsh-users/zsh-syntax-highlighting
zinit light agkozak/zsh-z

# oh-my-zsh plugins
zinit ice wait"1" lucid
zinit snippet 'https://github.com/ohmyzsh/ohmyzsh/blob/master/plugins/colored-man-pages/colored-man-pages.plugin.zsh'
zinit snippet 'https://github.com/ohmyzsh/ohmyzsh/blob/master/plugins/copyfile/copyfile.plugin.zsh'
zinit snippet 'https://github.com/ohmyzsh/ohmyzsh/blob/master/plugins/copypath/copypath.plugin.zsh'
zinit snippet 'https://github.com/ohmyzsh/ohmyzsh/blob/master/plugins/extract/extract.plugin.zsh'
zinit snippet 'https://github.com/ohmyzsh/ohmyzsh/blob/master/plugins/git-auto-fetch/git-auto-fetch.plugin.zsh'
zinit snippet 'https://github.com/ohmyzsh/ohmyzsh/blob/master/plugins/gitignore/gitignore.plugin.zsh'
zinit snippet 'https://github.com/ohmyzsh/ohmyzsh/blob/master/plugins/rsync/rsync.plugin.zsh'
zinit snippet 'https://github.com/ohmyzsh/ohmyzsh/blob/master/plugins/zsh-interactive-cd/zsh-interactive-cd.plugin.zsh'
zinit snippet 'https://github.com/ohmyzsh/ohmyzsh/blob/master/plugins/github/github.plugin.zsh'

### End of Zinit's installer chunk
