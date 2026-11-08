# Keep the instant prompt before Oh My Zsh and other interactive setup.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

unsetopt NOMATCH

# Enable Oh My Zsh and plugins.
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"
plugins=(
  git z dirhistory fzf aliases docker docker-compose common-aliases
  zsh-syntax-highlighting zsh-autosuggestions ohmyzsh-full-autoupdate
)
source "$ZSH/oh-my-zsh.sh"
# Reuse a configured prompt; run p10k configure to customize a new machine.
[[ ! -f "$HOME/.p10k.zsh" ]] || source "$HOME/.p10k.zsh"

alias ls='lsd'
